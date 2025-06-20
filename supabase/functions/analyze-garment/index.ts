import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { Buffer } from "https://deno.land/std@0.177.0/io/buffer.ts";
import { encode } from "https://deno.land/std@0.177.0/encoding/base64.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AnalyzeRequest {
  imageUrl: string
  userId: string
}

interface AIResponse {
  category: string
  colors: string[]
  brand?: string
  description?: string
  error?: string
}

interface AnalyzeResponse {
  success: boolean
  data?: AIResponse
  error?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    // Parse request body
    const { imageUrl, userId }: AnalyzeRequest = await req.json()

    if (!imageUrl || !userId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing imageUrl or userId' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400 
        }
      )
    }

    // Get OpenAI API key from environment
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      throw new Error('OpenAI API key not configured')
    }

    // Verify image URL is from our Supabase Storage (security check)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    if (!imageUrl.includes(supabaseUrl || '')) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid image URL' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400 
        }
      )
    }

    // --- New: Fetch image data from URL ---
    console.log(`Fetching image from URL: ${imageUrl}`);
    const imageResponse = await fetch(imageUrl);
    if (!imageResponse.ok) {
      throw new Error(`Failed to fetch image: ${imageResponse.statusText}`);
    }
    const imageArrayBuffer = await imageResponse.arrayBuffer();
    const imageUint8Array = new Buffer(imageArrayBuffer).bytes();
    const imageBase64 = encode(imageUint8Array);
    const imageDataUrl = `data:image/jpeg;base64,${imageBase64}`;
    console.log(`Successfully fetched and encoded image. Data URI starts with: ${imageDataUrl.substring(0, 50)}...`);
    // --- End New ---

    // Call OpenAI GPT-4o Vision API
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openaiApiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: `Analyze this clothing item and return ONLY a JSON object with:
- "category": one of "Top", "Bottom", "Dress", "Outerwear", "Shoes", "Accessories"
- "colors": array of 1-2 dominant colors (e.g., ["blue", "white"])
- "brand": (optional) the brand name if visible/identifiable
- "description": (optional) a short, one-sentence description

If analysis is impossible, return a fallback JSON with an error field, like:
{"category": "unknown", "colors": [], "error": "Could not identify garment."}

Only return valid JSON, nothing else.`
              },
              {
                type: 'image_url',
                image_url: {
                  url: imageDataUrl, // Use Base64 Data URI instead of the original URL
                }
              }
            ]
          }
        ],
        max_tokens: 150, // Increased max_tokens
        temperature: 0.1
      })
    })

    if (!openaiResponse.ok) {
      const errorData = await openaiResponse.json().catch(() => null) // Try to parse JSON error
      const errorText = await openaiResponse.text().catch(() => '') // Get raw text if JSON fails
      let detail = errorData?.error?.message || errorData?.error || errorText || `Status: ${openaiResponse.status}`
      console.error('OpenAI API error:', detail)
      throw new Error(`OpenAI API error: ${detail}`)
    }

    const openaiData = await openaiResponse.json()
    const aiContent = openaiData.choices[0]?.message?.content
    console.log("[Edge Function] OpenAI raw aiContent:", aiContent);

    if (!aiContent) {
        console.error("[Edge Function] No aiContent from OpenAI.");
        throw new Error('No response content from OpenAI');
    }

    // --- NEW: Robust JSON Extraction from potential markdown ---
    let cleanedJsonString = aiContent.trim();
    // Regex to find JSON within ```json ... ``` or just ``` ... ```
    const markdownRegex = /^```(?:json)?\s*([\s\S]*?)\s*```$/;
    const match = cleanedJsonString.match(markdownRegex);
    if (match && match[1]) {
        cleanedJsonString = match[1].trim(); // Extract content within the backticks
        console.log("[Edge Function] Extracted JSON from markdown:", cleanedJsonString);
    } else {
        // If no markdown block, assume it might be direct JSON (or still have issues)
        console.log("[Edge Function] No markdown detected, using trimmed aiContent directly for parsing.");
    }
    // --- End NEW ---

    let aiResponseData: AIResponse;
    try {
        // Attempt to parse the cleaned string
        aiResponseData = JSON.parse(cleanedJsonString); 
    } catch (parseError) {
        console.error('[Edge Function] Failed to parse cleaned JSON string:', cleanedJsonString);
        console.error('[Edge Function] Original aiContent before cleaning:', aiContent);
        throw new Error('Invalid AI response format even after cleaning attempts');
    }

    // Handle case where AI returns our defined error structure
    if (aiResponseData.error) {
        console.warn(`[Edge Function] AI reported an issue with the image: ${aiResponseData.error}`);
        return new Response(
            JSON.stringify({ success: false, error: `AI Analysis Note: ${aiResponseData.error}`, data: aiResponseData }),
            { 
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 200 // Status 200 because the function executed correctly
            }
        );
    }
    
    // Validate primary response structure
    if (!aiResponseData.category || !Array.isArray(aiResponseData.colors)) {
      console.error('Validation failed: category or colors missing.', aiResponseData)
      throw new Error('Invalid AI response structure: "category" and "colors" are required.')
    }

    // Return successful response
    const response: AnalyzeResponse = {
      success: true,
      data: aiResponseData
    }

    return new Response(
      JSON.stringify(response),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Edge Function error:', error)
    
    const errorResponse: AnalyzeResponse = {
      success: false,
      error: error.message || 'Internal server error'
    }

    return new Response(
      JSON.stringify(errorResponse),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
}) 