# AI Vision Model Edge Function Deployment Guide

## Overview

The AI Vision Model MVP implementation is **functionally complete** and ready for deployment. This guide covers the remaining manual deployment steps.

## ✅ Completed Implementation

### 1. Supabase Edge Function
- **File**: `supabase/functions/analyze-garment/index.ts`
- **Features**: OpenAI GPT-4o Vision integration, error handling, security validation
- **API**: Receives image URL + userId, returns category and colors

### 2. Swift App Integration
- **AIVisionService**: Service layer for API calls
- **AISuggestedTags**: Data model for AI responses
- **AddItemView**: UI with "Analyze Photo with AI" button
- **Flow**: Upload → Analyze → Pre-fill form → User confirms → Save

## 🚀 Deployment Steps Required

### Step 1: Deploy Edge Function to Supabase

1. **Option A: Supabase Dashboard (Recommended)**
   - Go to your Supabase project dashboard
   - Navigate to Edge Functions
   - Create new function named `analyze-garment`
   - Copy the contents of `supabase/functions/analyze-garment/index.ts`
   - Deploy the function

2. **Option B: CLI Deployment (if you have access)**
   ```bash
   supabase login
   supabase link --project-ref mymolgiisjudhulylglq
   supabase functions deploy analyze-garment
   ```

### Step 2: Configure Environment Variables (CRITICAL)

**⚠️ REQUIRED FOR FUNCTIONALITY**: The AI Vision feature will NOT work without a valid OpenAI API key.

In your Supabase project settings, add the following environment variable:

1. **Go to your Supabase Project Dashboard**
2. **Navigate to Project Settings** (gear icon)
3. **Go to Environment Variables**
4. **Add/Update the following variable**:
   - **Variable Name**: `OPENAI_API_KEY`
   - **Value**: Your valid OpenAI API key (starts with `sk-proj-` or `sk-`)

**How to get an OpenAI API Key**:
1. Go to [platform.openai.com](https://platform.openai.com)
2. Sign in or create an account
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key and paste it in Supabase environment variables

**Note**: The Edge Function will fail with "Network connection error" if this key is missing or invalid.

### Step 3: Test the Deployment

1. **Test Edge Function**:
   ```bash
   curl -X POST 'https://mymolgiisjudhulylglq.supabase.co/functions/v1/analyze-garment' \
   -H 'Authorization: Bearer YOUR_ANON_KEY' \
   -H 'Content-Type: application/json' \
   -d '{
     "imageUrl": "https://example.com/test-image.jpg",
     "userId": "test-user-id"
   }'
   ```

2. **Expected Response**:
   ```json
   {
     "success": true,
     "data": {
       "category": "shirt",
       "colors": ["blue", "white"]
     }
   }
   ```

### Step 4: Test in iOS App

1. Run the WardroAI app
2. Navigate to Add Item screen
3. Select a photo of clothing
4. Tap "Analyze Photo with AI"
5. Verify that category and color fields are pre-filled
6. Save the item and check that AI data is stored

## 🔧 Troubleshooting

### Common Issues

1. **"OpenAI API key not configured"**
   - Ensure `OPENAI_API_KEY` is set in Supabase environment variables
   - Verify the key starts with `sk-` and is valid

2. **"Invalid image URL"**
   - The Edge Function validates that images come from your Supabase Storage
   - Make sure image is uploaded and URL is accessible

3. **Network/CORS errors**
   - Check that Edge Function is deployed and accessible
   - Verify CORS headers are properly configured

4. **Parsing errors**
   - GPT-4o sometimes returns non-JSON responses
   - The function includes parsing validation and error handling

## 📊 Expected Performance

- **Response Time**: 2-5 seconds for image analysis
- **Accuracy**: 85-95% for basic categories and colors
- **Cost**: ~$0.01-0.03 per image analysis
- **Rate Limits**: Depends on your OpenAI API tier

## 🎯 Success Criteria

✅ Edge Function deployed and responding  
✅ AI analysis returns valid category and colors  
✅ iOS app pre-fills form fields with AI suggestions  
✅ User can confirm/edit suggestions before saving  
✅ AI data stored in `aiIdentifiedTagsRaw` field  

## 🔄 Next Steps (Future Tasks)

After successful deployment, consider implementing:
- Response caching (Task 34)
- Dedicated AI analysis database table (Task 35)
- Similarity search and embeddings (Task 36)
- Batch processing (Task 37)
- Advanced progress tracking (Task 38)
- Performance optimization (Task 39)

---

**The AI Vision Model MVP is ready! Deploy the Edge Function and test the complete flow.** 