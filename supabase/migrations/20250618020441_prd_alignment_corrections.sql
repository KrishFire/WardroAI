-- Enable the pgvector extension
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;

-- Table: users
ALTER TABLE public.users ADD COLUMN subscription_tier TEXT;
ALTER TABLE public.users ADD COLUMN pro_subscription_expires_at TIMESTAMPTZ NULL;
ALTER TABLE public.users ADD COLUMN location_permission_granted BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE public.users ADD COLUMN calendar_permission_granted BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE public.users ADD COLUMN style_preferences_onboarding JSONB NULL;
ALTER TABLE public.users ADD COLUMN color_palette_info JSONB NULL;
ALTER TABLE public.users ADD COLUMN hashed_anon_id_for_affiliate TEXT NULL;
ALTER TABLE public.users ADD CONSTRAINT users_hashed_anon_id_for_affiliate_key UNIQUE (hashed_anon_id_for_affiliate);

-- Table: garment_items
ALTER TABLE public.garment_items ADD COLUMN photo_thumbnail_url TEXT NULL;
ALTER TABLE public.garment_items ADD COLUMN primary_color TEXT NULL;
ALTER TABLE public.garment_items ADD COLUMN material TEXT NULL;
ALTER TABLE public.garment_items ADD COLUMN seasonality TEXT[] NULL;
ALTER TABLE public.garment_items ADD COLUMN occasions TEXT[] NULL;
ALTER TABLE public.garment_items ADD COLUMN price NUMERIC(10, 2) NULL;
ALTER TABLE public.garment_items ADD COLUMN notes TEXT NULL;
ALTER TABLE public.garment_items ADD COLUMN item_embedding extensions.vector(384) NULL;
ALTER TABLE public.garment_items ADD COLUMN ai_identified_tags_raw JSONB NULL;
ALTER TABLE public.garment_items ADD COLUMN is_archived BOOLEAN DEFAULT false NOT NULL;

-- Table: outfit_suggestions
ALTER TABLE public.outfit_suggestions ADD COLUMN suggested_at TIMESTAMPTZ DEFAULT now() NOT NULL;
ALTER TABLE public.outfit_suggestions ADD COLUMN weather_context JSONB NULL;
ALTER TABLE public.outfit_suggestions ADD COLUMN calendar_event_context TEXT NULL;
ALTER TABLE public.outfit_suggestions ADD COLUMN ai_rationale TEXT NULL;
ALTER TABLE public.outfit_suggestions ADD COLUMN user_feedback_status TEXT NULL;
ALTER TABLE public.outfit_suggestions ADD COLUMN customization_details JSONB NULL;

-- Table: logged_outfits
ALTER TABLE public.logged_outfits ADD COLUMN occasion TEXT NULL;
ALTER TABLE public.logged_outfits ADD COLUMN photo_url_selfie TEXT NULL;

-- Table: user_preferences_derived
ALTER TABLE public.user_preferences_derived ADD COLUMN liked_item_ids INTEGER[] NULL;
ALTER TABLE public.user_preferences_derived ADD COLUMN disliked_item_ids INTEGER[] NULL;
ALTER TABLE public.user_preferences_derived ADD COLUMN preference_vector extensions.vector(128) NULL;

-- Table: ai_shopping_suggestions
ALTER TABLE public.ai_shopping_suggestions ADD COLUMN affiliate_link TEXT NULL;
ALTER TABLE public.ai_shopping_suggestions ADD COLUMN product_details_snapshot JSONB NULL;
