create sequence "public"."ai_shopping_suggestions_id_seq";

create sequence "public"."garment_items_id_seq";

create sequence "public"."logged_outfits_id_seq";

create sequence "public"."outfit_suggestions_id_seq";

create sequence "public"."wishlist_items_id_seq";

create table "public"."ai_shopping_suggestions" (
    "id" integer not null default nextval('ai_shopping_suggestions_id_seq'::regclass),
    "user_id" uuid not null,
    "suggested_item_name" text not null,
    "description" text,
    "category" text,
    "reasoning" text,
    "source_url" text,
    "image_url" text,
    "price_estimate_min" numeric,
    "price_estimate_max" numeric,
    "currency_code" text default 'USD'::text,
    "feedback" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."ai_shopping_suggestions" enable row level security;

create table "public"."garment_items" (
    "id" integer not null default nextval('garment_items_id_seq'::regclass),
    "user_id" uuid not null,
    "name" text not null,
    "description" text,
    "category" text not null,
    "sub_category" text,
    "colors" text[],
    "patterns" text[],
    "fabrics" text[],
    "brand" text,
    "size" text,
    "purchase_date" date,
    "image_url" text,
    "last_worn_date" timestamp with time zone,
    "wear_count" integer default 0,
    "is_favorite" boolean default false,
    "custom_tags" text[],
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."garment_items" enable row level security;

create table "public"."logged_outfit_items" (
    "logged_outfit_id" integer not null,
    "garment_item_id" integer not null
);


alter table "public"."logged_outfit_items" enable row level security;

create table "public"."logged_outfits" (
    "id" integer not null default nextval('logged_outfits_id_seq'::regclass),
    "user_id" uuid not null,
    "outfit_suggestion_id" integer,
    "name" text,
    "date_worn" date not null default CURRENT_DATE,
    "notes" text,
    "rating" integer,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."logged_outfits" enable row level security;

create table "public"."outfit_suggestion_items" (
    "outfit_suggestion_id" integer not null,
    "garment_item_id" integer not null
);


alter table "public"."outfit_suggestion_items" enable row level security;

create table "public"."outfit_suggestions" (
    "id" integer not null default nextval('outfit_suggestions_id_seq'::regclass),
    "user_id" uuid not null,
    "name" text,
    "suggestion_source" text,
    "notes" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."outfit_suggestions" enable row level security;

create table "public"."user_preferences_derived" (
    "user_id" uuid not null,
    "preferred_colors" text[],
    "disliked_colors" text[],
    "preferred_categories" text[],
    "disliked_categories" text[],
    "preferred_styles" text[],
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."user_preferences_derived" enable row level security;

create table "public"."users" (
    "id" uuid not null,
    "username" text,
    "full_name" text,
    "avatar_url" text,
    "updated_at" timestamp with time zone default now(),
    "created_at" timestamp with time zone default now()
);


alter table "public"."users" enable row level security;

create table "public"."wishlist_items" (
    "id" integer not null default nextval('wishlist_items_id_seq'::regclass),
    "user_id" uuid not null,
    "item_name" text not null,
    "description" text,
    "category" text,
    "desired_color" text,
    "desired_brand" text,
    "desired_size" text,
    "item_url" text,
    "image_url" text,
    "notes" text,
    "priority" integer default 2,
    "is_purchased" boolean default false,
    "date_added" timestamp with time zone default now(),
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."wishlist_items" enable row level security;

alter sequence "public"."ai_shopping_suggestions_id_seq" owned by "public"."ai_shopping_suggestions"."id";

alter sequence "public"."garment_items_id_seq" owned by "public"."garment_items"."id";

alter sequence "public"."logged_outfits_id_seq" owned by "public"."logged_outfits"."id";

alter sequence "public"."outfit_suggestions_id_seq" owned by "public"."outfit_suggestions"."id";

alter sequence "public"."wishlist_items_id_seq" owned by "public"."wishlist_items"."id";

CREATE UNIQUE INDEX ai_shopping_suggestions_pkey ON public.ai_shopping_suggestions USING btree (id);

CREATE UNIQUE INDEX garment_items_pkey ON public.garment_items USING btree (id);

CREATE INDEX idx_ai_shopping_suggestions_user_id ON public.ai_shopping_suggestions USING btree (user_id);

CREATE INDEX idx_fts_garment_items_name_desc ON public.garment_items USING gin (to_tsvector('english'::regconfig, ((COALESCE(name, ''::text) || ' '::text) || COALESCE(description, ''::text))));

CREATE INDEX idx_garment_items_brand ON public.garment_items USING btree (brand);

CREATE INDEX idx_garment_items_category ON public.garment_items USING btree (category);

CREATE INDEX idx_garment_items_is_favorite ON public.garment_items USING btree (is_favorite);

CREATE INDEX idx_garment_items_last_worn_date ON public.garment_items USING btree (last_worn_date DESC NULLS LAST);

CREATE INDEX idx_garment_items_sub_category ON public.garment_items USING btree (sub_category);

CREATE INDEX idx_garment_items_user_id ON public.garment_items USING btree (user_id);

CREATE INDEX idx_gin_garment_items_colors ON public.garment_items USING gin (colors);

CREATE INDEX idx_gin_garment_items_custom_tags ON public.garment_items USING gin (custom_tags);

CREATE INDEX idx_gin_garment_items_fabrics ON public.garment_items USING gin (fabrics);

CREATE INDEX idx_gin_garment_items_patterns ON public.garment_items USING gin (patterns);

CREATE INDEX idx_gin_user_preferences_disliked_categories ON public.user_preferences_derived USING gin (disliked_categories);

CREATE INDEX idx_gin_user_preferences_disliked_colors ON public.user_preferences_derived USING gin (disliked_colors);

CREATE INDEX idx_gin_user_preferences_preferred_categories ON public.user_preferences_derived USING gin (preferred_categories);

CREATE INDEX idx_gin_user_preferences_preferred_colors ON public.user_preferences_derived USING gin (preferred_colors);

CREATE INDEX idx_gin_user_preferences_preferred_styles ON public.user_preferences_derived USING gin (preferred_styles);

CREATE INDEX idx_logged_outfit_items_garment_item_id ON public.logged_outfit_items USING btree (garment_item_id);

CREATE INDEX idx_logged_outfits_date_worn ON public.logged_outfits USING btree (date_worn DESC);

CREATE INDEX idx_logged_outfits_outfit_suggestion_id ON public.logged_outfits USING btree (outfit_suggestion_id);

CREATE INDEX idx_logged_outfits_user_id ON public.logged_outfits USING btree (user_id);

CREATE INDEX idx_outfit_suggestion_items_garment_item_id ON public.outfit_suggestion_items USING btree (garment_item_id);

CREATE INDEX idx_outfit_suggestions_user_id ON public.outfit_suggestions USING btree (user_id);

CREATE INDEX idx_users_username ON public.users USING btree (username);

CREATE INDEX idx_wishlist_items_is_purchased ON public.wishlist_items USING btree (is_purchased);

CREATE INDEX idx_wishlist_items_priority ON public.wishlist_items USING btree (priority);

CREATE INDEX idx_wishlist_items_user_id ON public.wishlist_items USING btree (user_id);

CREATE UNIQUE INDEX logged_outfit_items_pkey ON public.logged_outfit_items USING btree (logged_outfit_id, garment_item_id);

CREATE UNIQUE INDEX logged_outfits_pkey ON public.logged_outfits USING btree (id);

CREATE UNIQUE INDEX outfit_suggestion_items_pkey ON public.outfit_suggestion_items USING btree (outfit_suggestion_id, garment_item_id);

CREATE UNIQUE INDEX outfit_suggestions_pkey ON public.outfit_suggestions USING btree (id);

CREATE UNIQUE INDEX user_preferences_derived_pkey ON public.user_preferences_derived USING btree (user_id);

CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id);

CREATE UNIQUE INDEX users_username_key ON public.users USING btree (username);

CREATE UNIQUE INDEX wishlist_items_pkey ON public.wishlist_items USING btree (id);

alter table "public"."ai_shopping_suggestions" add constraint "ai_shopping_suggestions_pkey" PRIMARY KEY using index "ai_shopping_suggestions_pkey";

alter table "public"."garment_items" add constraint "garment_items_pkey" PRIMARY KEY using index "garment_items_pkey";

alter table "public"."logged_outfit_items" add constraint "logged_outfit_items_pkey" PRIMARY KEY using index "logged_outfit_items_pkey";

alter table "public"."logged_outfits" add constraint "logged_outfits_pkey" PRIMARY KEY using index "logged_outfits_pkey";

alter table "public"."outfit_suggestion_items" add constraint "outfit_suggestion_items_pkey" PRIMARY KEY using index "outfit_suggestion_items_pkey";

alter table "public"."outfit_suggestions" add constraint "outfit_suggestions_pkey" PRIMARY KEY using index "outfit_suggestions_pkey";

alter table "public"."user_preferences_derived" add constraint "user_preferences_derived_pkey" PRIMARY KEY using index "user_preferences_derived_pkey";

alter table "public"."users" add constraint "users_pkey" PRIMARY KEY using index "users_pkey";

alter table "public"."wishlist_items" add constraint "wishlist_items_pkey" PRIMARY KEY using index "wishlist_items_pkey";

alter table "public"."ai_shopping_suggestions" add constraint "ai_shopping_suggestions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."ai_shopping_suggestions" validate constraint "ai_shopping_suggestions_user_id_fkey";

alter table "public"."garment_items" add constraint "garment_items_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."garment_items" validate constraint "garment_items_user_id_fkey";

alter table "public"."logged_outfit_items" add constraint "logged_outfit_items_garment_item_id_fkey" FOREIGN KEY (garment_item_id) REFERENCES garment_items(id) ON DELETE CASCADE not valid;

alter table "public"."logged_outfit_items" validate constraint "logged_outfit_items_garment_item_id_fkey";

alter table "public"."logged_outfit_items" add constraint "logged_outfit_items_logged_outfit_id_fkey" FOREIGN KEY (logged_outfit_id) REFERENCES logged_outfits(id) ON DELETE CASCADE not valid;

alter table "public"."logged_outfit_items" validate constraint "logged_outfit_items_logged_outfit_id_fkey";

alter table "public"."logged_outfits" add constraint "logged_outfits_outfit_suggestion_id_fkey" FOREIGN KEY (outfit_suggestion_id) REFERENCES outfit_suggestions(id) ON DELETE SET NULL not valid;

alter table "public"."logged_outfits" validate constraint "logged_outfits_outfit_suggestion_id_fkey";

alter table "public"."logged_outfits" add constraint "logged_outfits_rating_check" CHECK (((rating >= 1) AND (rating <= 5))) not valid;

alter table "public"."logged_outfits" validate constraint "logged_outfits_rating_check";

alter table "public"."logged_outfits" add constraint "logged_outfits_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."logged_outfits" validate constraint "logged_outfits_user_id_fkey";

alter table "public"."outfit_suggestion_items" add constraint "outfit_suggestion_items_garment_item_id_fkey" FOREIGN KEY (garment_item_id) REFERENCES garment_items(id) ON DELETE CASCADE not valid;

alter table "public"."outfit_suggestion_items" validate constraint "outfit_suggestion_items_garment_item_id_fkey";

alter table "public"."outfit_suggestion_items" add constraint "outfit_suggestion_items_outfit_suggestion_id_fkey" FOREIGN KEY (outfit_suggestion_id) REFERENCES outfit_suggestions(id) ON DELETE CASCADE not valid;

alter table "public"."outfit_suggestion_items" validate constraint "outfit_suggestion_items_outfit_suggestion_id_fkey";

alter table "public"."outfit_suggestions" add constraint "outfit_suggestions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."outfit_suggestions" validate constraint "outfit_suggestions_user_id_fkey";

alter table "public"."user_preferences_derived" add constraint "user_preferences_derived_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."user_preferences_derived" validate constraint "user_preferences_derived_user_id_fkey";

alter table "public"."users" add constraint "users_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."users" validate constraint "users_id_fkey";

alter table "public"."users" add constraint "users_username_key" UNIQUE using index "users_username_key";

alter table "public"."wishlist_items" add constraint "wishlist_items_priority_check" CHECK (((priority >= 1) AND (priority <= 3))) not valid;

alter table "public"."wishlist_items" validate constraint "wishlist_items_priority_check";

alter table "public"."wishlist_items" add constraint "wishlist_items_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."wishlist_items" validate constraint "wishlist_items_user_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_logged_outfit_for_preferences()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- When a logged_outfit is inserted, updated (or deleted),
    -- update the user_preferences_derived table for that user.
    -- This is a placeholder for more complex logic.
    -- For now, it ensures a preference row exists and updates its 'updated_at'.
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        INSERT INTO public.user_preferences_derived (user_id, created_at, updated_at)
        VALUES (NEW.user_id, now(), now())
        ON CONFLICT (user_id) DO UPDATE SET updated_at = now();
    ELSIF TG_OP = 'DELETE' THEN
        -- If a logged outfit is deleted, also update the preferences timestamp
        -- as this might change the derived preferences.
        UPDATE public.user_preferences_derived
        SET updated_at = now()
        WHERE user_id = OLD.user_id;
        -- Optionally, insert if not exists, though less likely to be needed on delete
        -- IF NOT FOUND THEN
        --     INSERT INTO public.user_preferences_derived (user_id, created_at, updated_at)
        --     VALUES (OLD.user_id, now(), now())
        --     ON CONFLICT (user_id) DO NOTHING; -- Or DO UPDATE if necessary
        -- END IF;
    END IF;

    -- Return value depends on the operation
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$function$
;

grant delete on table "public"."ai_shopping_suggestions" to "anon";

grant insert on table "public"."ai_shopping_suggestions" to "anon";

grant references on table "public"."ai_shopping_suggestions" to "anon";

grant select on table "public"."ai_shopping_suggestions" to "anon";

grant trigger on table "public"."ai_shopping_suggestions" to "anon";

grant truncate on table "public"."ai_shopping_suggestions" to "anon";

grant update on table "public"."ai_shopping_suggestions" to "anon";

grant delete on table "public"."ai_shopping_suggestions" to "authenticated";

grant insert on table "public"."ai_shopping_suggestions" to "authenticated";

grant references on table "public"."ai_shopping_suggestions" to "authenticated";

grant select on table "public"."ai_shopping_suggestions" to "authenticated";

grant trigger on table "public"."ai_shopping_suggestions" to "authenticated";

grant truncate on table "public"."ai_shopping_suggestions" to "authenticated";

grant update on table "public"."ai_shopping_suggestions" to "authenticated";

grant delete on table "public"."ai_shopping_suggestions" to "service_role";

grant insert on table "public"."ai_shopping_suggestions" to "service_role";

grant references on table "public"."ai_shopping_suggestions" to "service_role";

grant select on table "public"."ai_shopping_suggestions" to "service_role";

grant trigger on table "public"."ai_shopping_suggestions" to "service_role";

grant truncate on table "public"."ai_shopping_suggestions" to "service_role";

grant update on table "public"."ai_shopping_suggestions" to "service_role";

grant delete on table "public"."garment_items" to "anon";

grant insert on table "public"."garment_items" to "anon";

grant references on table "public"."garment_items" to "anon";

grant select on table "public"."garment_items" to "anon";

grant trigger on table "public"."garment_items" to "anon";

grant truncate on table "public"."garment_items" to "anon";

grant update on table "public"."garment_items" to "anon";

grant delete on table "public"."garment_items" to "authenticated";

grant insert on table "public"."garment_items" to "authenticated";

grant references on table "public"."garment_items" to "authenticated";

grant select on table "public"."garment_items" to "authenticated";

grant trigger on table "public"."garment_items" to "authenticated";

grant truncate on table "public"."garment_items" to "authenticated";

grant update on table "public"."garment_items" to "authenticated";

grant delete on table "public"."garment_items" to "service_role";

grant insert on table "public"."garment_items" to "service_role";

grant references on table "public"."garment_items" to "service_role";

grant select on table "public"."garment_items" to "service_role";

grant trigger on table "public"."garment_items" to "service_role";

grant truncate on table "public"."garment_items" to "service_role";

grant update on table "public"."garment_items" to "service_role";

grant delete on table "public"."logged_outfit_items" to "anon";

grant insert on table "public"."logged_outfit_items" to "anon";

grant references on table "public"."logged_outfit_items" to "anon";

grant select on table "public"."logged_outfit_items" to "anon";

grant trigger on table "public"."logged_outfit_items" to "anon";

grant truncate on table "public"."logged_outfit_items" to "anon";

grant update on table "public"."logged_outfit_items" to "anon";

grant delete on table "public"."logged_outfit_items" to "authenticated";

grant insert on table "public"."logged_outfit_items" to "authenticated";

grant references on table "public"."logged_outfit_items" to "authenticated";

grant select on table "public"."logged_outfit_items" to "authenticated";

grant trigger on table "public"."logged_outfit_items" to "authenticated";

grant truncate on table "public"."logged_outfit_items" to "authenticated";

grant update on table "public"."logged_outfit_items" to "authenticated";

grant delete on table "public"."logged_outfit_items" to "service_role";

grant insert on table "public"."logged_outfit_items" to "service_role";

grant references on table "public"."logged_outfit_items" to "service_role";

grant select on table "public"."logged_outfit_items" to "service_role";

grant trigger on table "public"."logged_outfit_items" to "service_role";

grant truncate on table "public"."logged_outfit_items" to "service_role";

grant update on table "public"."logged_outfit_items" to "service_role";

grant delete on table "public"."logged_outfits" to "anon";

grant insert on table "public"."logged_outfits" to "anon";

grant references on table "public"."logged_outfits" to "anon";

grant select on table "public"."logged_outfits" to "anon";

grant trigger on table "public"."logged_outfits" to "anon";

grant truncate on table "public"."logged_outfits" to "anon";

grant update on table "public"."logged_outfits" to "anon";

grant delete on table "public"."logged_outfits" to "authenticated";

grant insert on table "public"."logged_outfits" to "authenticated";

grant references on table "public"."logged_outfits" to "authenticated";

grant select on table "public"."logged_outfits" to "authenticated";

grant trigger on table "public"."logged_outfits" to "authenticated";

grant truncate on table "public"."logged_outfits" to "authenticated";

grant update on table "public"."logged_outfits" to "authenticated";

grant delete on table "public"."logged_outfits" to "service_role";

grant insert on table "public"."logged_outfits" to "service_role";

grant references on table "public"."logged_outfits" to "service_role";

grant select on table "public"."logged_outfits" to "service_role";

grant trigger on table "public"."logged_outfits" to "service_role";

grant truncate on table "public"."logged_outfits" to "service_role";

grant update on table "public"."logged_outfits" to "service_role";

grant delete on table "public"."outfit_suggestion_items" to "anon";

grant insert on table "public"."outfit_suggestion_items" to "anon";

grant references on table "public"."outfit_suggestion_items" to "anon";

grant select on table "public"."outfit_suggestion_items" to "anon";

grant trigger on table "public"."outfit_suggestion_items" to "anon";

grant truncate on table "public"."outfit_suggestion_items" to "anon";

grant update on table "public"."outfit_suggestion_items" to "anon";

grant delete on table "public"."outfit_suggestion_items" to "authenticated";

grant insert on table "public"."outfit_suggestion_items" to "authenticated";

grant references on table "public"."outfit_suggestion_items" to "authenticated";

grant select on table "public"."outfit_suggestion_items" to "authenticated";

grant trigger on table "public"."outfit_suggestion_items" to "authenticated";

grant truncate on table "public"."outfit_suggestion_items" to "authenticated";

grant update on table "public"."outfit_suggestion_items" to "authenticated";

grant delete on table "public"."outfit_suggestion_items" to "service_role";

grant insert on table "public"."outfit_suggestion_items" to "service_role";

grant references on table "public"."outfit_suggestion_items" to "service_role";

grant select on table "public"."outfit_suggestion_items" to "service_role";

grant trigger on table "public"."outfit_suggestion_items" to "service_role";

grant truncate on table "public"."outfit_suggestion_items" to "service_role";

grant update on table "public"."outfit_suggestion_items" to "service_role";

grant delete on table "public"."outfit_suggestions" to "anon";

grant insert on table "public"."outfit_suggestions" to "anon";

grant references on table "public"."outfit_suggestions" to "anon";

grant select on table "public"."outfit_suggestions" to "anon";

grant trigger on table "public"."outfit_suggestions" to "anon";

grant truncate on table "public"."outfit_suggestions" to "anon";

grant update on table "public"."outfit_suggestions" to "anon";

grant delete on table "public"."outfit_suggestions" to "authenticated";

grant insert on table "public"."outfit_suggestions" to "authenticated";

grant references on table "public"."outfit_suggestions" to "authenticated";

grant select on table "public"."outfit_suggestions" to "authenticated";

grant trigger on table "public"."outfit_suggestions" to "authenticated";

grant truncate on table "public"."outfit_suggestions" to "authenticated";

grant update on table "public"."outfit_suggestions" to "authenticated";

grant delete on table "public"."outfit_suggestions" to "service_role";

grant insert on table "public"."outfit_suggestions" to "service_role";

grant references on table "public"."outfit_suggestions" to "service_role";

grant select on table "public"."outfit_suggestions" to "service_role";

grant trigger on table "public"."outfit_suggestions" to "service_role";

grant truncate on table "public"."outfit_suggestions" to "service_role";

grant update on table "public"."outfit_suggestions" to "service_role";

grant delete on table "public"."user_preferences_derived" to "anon";

grant insert on table "public"."user_preferences_derived" to "anon";

grant references on table "public"."user_preferences_derived" to "anon";

grant select on table "public"."user_preferences_derived" to "anon";

grant trigger on table "public"."user_preferences_derived" to "anon";

grant truncate on table "public"."user_preferences_derived" to "anon";

grant update on table "public"."user_preferences_derived" to "anon";

grant delete on table "public"."user_preferences_derived" to "authenticated";

grant insert on table "public"."user_preferences_derived" to "authenticated";

grant references on table "public"."user_preferences_derived" to "authenticated";

grant select on table "public"."user_preferences_derived" to "authenticated";

grant trigger on table "public"."user_preferences_derived" to "authenticated";

grant truncate on table "public"."user_preferences_derived" to "authenticated";

grant update on table "public"."user_preferences_derived" to "authenticated";

grant delete on table "public"."user_preferences_derived" to "service_role";

grant insert on table "public"."user_preferences_derived" to "service_role";

grant references on table "public"."user_preferences_derived" to "service_role";

grant select on table "public"."user_preferences_derived" to "service_role";

grant trigger on table "public"."user_preferences_derived" to "service_role";

grant truncate on table "public"."user_preferences_derived" to "service_role";

grant update on table "public"."user_preferences_derived" to "service_role";

grant delete on table "public"."users" to "anon";

grant insert on table "public"."users" to "anon";

grant references on table "public"."users" to "anon";

grant select on table "public"."users" to "anon";

grant trigger on table "public"."users" to "anon";

grant truncate on table "public"."users" to "anon";

grant update on table "public"."users" to "anon";

grant delete on table "public"."users" to "authenticated";

grant insert on table "public"."users" to "authenticated";

grant references on table "public"."users" to "authenticated";

grant select on table "public"."users" to "authenticated";

grant trigger on table "public"."users" to "authenticated";

grant truncate on table "public"."users" to "authenticated";

grant update on table "public"."users" to "authenticated";

grant delete on table "public"."users" to "service_role";

grant insert on table "public"."users" to "service_role";

grant references on table "public"."users" to "service_role";

grant select on table "public"."users" to "service_role";

grant trigger on table "public"."users" to "service_role";

grant truncate on table "public"."users" to "service_role";

grant update on table "public"."users" to "service_role";

grant delete on table "public"."wishlist_items" to "anon";

grant insert on table "public"."wishlist_items" to "anon";

grant references on table "public"."wishlist_items" to "anon";

grant select on table "public"."wishlist_items" to "anon";

grant trigger on table "public"."wishlist_items" to "anon";

grant truncate on table "public"."wishlist_items" to "anon";

grant update on table "public"."wishlist_items" to "anon";

grant delete on table "public"."wishlist_items" to "authenticated";

grant insert on table "public"."wishlist_items" to "authenticated";

grant references on table "public"."wishlist_items" to "authenticated";

grant select on table "public"."wishlist_items" to "authenticated";

grant trigger on table "public"."wishlist_items" to "authenticated";

grant truncate on table "public"."wishlist_items" to "authenticated";

grant update on table "public"."wishlist_items" to "authenticated";

grant delete on table "public"."wishlist_items" to "service_role";

grant insert on table "public"."wishlist_items" to "service_role";

grant references on table "public"."wishlist_items" to "service_role";

grant select on table "public"."wishlist_items" to "service_role";

grant trigger on table "public"."wishlist_items" to "service_role";

grant truncate on table "public"."wishlist_items" to "service_role";

grant update on table "public"."wishlist_items" to "service_role";

create policy "Users can update feedback on their AI shopping suggestions"
on "public"."ai_shopping_suggestions"
as permissive
for update
to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view their own AI shopping suggestions"
on "public"."ai_shopping_suggestions"
as permissive
for select
to public
using ((auth.uid() = user_id));


create policy "Users can delete their own garment items"
on "public"."garment_items"
as permissive
for delete
to public
using ((auth.uid() = user_id));


create policy "Users can insert their own garment items"
on "public"."garment_items"
as permissive
for insert
to public
with check ((auth.uid() = user_id));


create policy "Users can update their own garment items"
on "public"."garment_items"
as permissive
for update
to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view their own garment items"
on "public"."garment_items"
as permissive
for select
to public
using ((auth.uid() = user_id));


create policy "Users can delete items from their own logged outfits"
on "public"."logged_outfit_items"
as permissive
for delete
to public
using ((EXISTS ( SELECT 1
   FROM logged_outfits lo
  WHERE ((lo.id = logged_outfit_items.logged_outfit_id) AND (lo.user_id = auth.uid())))));


create policy "Users can insert items into their own logged outfits"
on "public"."logged_outfit_items"
as permissive
for insert
to public
with check ((EXISTS ( SELECT 1
   FROM logged_outfits lo
  WHERE ((lo.id = logged_outfit_items.logged_outfit_id) AND (lo.user_id = auth.uid())))));


create policy "Users can view items of their own logged outfits"
on "public"."logged_outfit_items"
as permissive
for select
to public
using ((EXISTS ( SELECT 1
   FROM logged_outfits lo
  WHERE ((lo.id = logged_outfit_items.logged_outfit_id) AND (lo.user_id = auth.uid())))));


create policy "Users can delete their own logged outfits"
on "public"."logged_outfits"
as permissive
for delete
to public
using ((auth.uid() = user_id));


create policy "Users can insert their own logged outfits"
on "public"."logged_outfits"
as permissive
for insert
to public
with check ((auth.uid() = user_id));


create policy "Users can update their own logged outfits"
on "public"."logged_outfits"
as permissive
for update
to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view their own logged outfits"
on "public"."logged_outfits"
as permissive
for select
to public
using ((auth.uid() = user_id));


create policy "Users can delete items from their own outfit suggestions"
on "public"."outfit_suggestion_items"
as permissive
for delete
to public
using ((EXISTS ( SELECT 1
   FROM outfit_suggestions os
  WHERE ((os.id = outfit_suggestion_items.outfit_suggestion_id) AND (os.user_id = auth.uid())))));


create policy "Users can insert items into their own outfit suggestions"
on "public"."outfit_suggestion_items"
as permissive
for insert
to public
with check ((EXISTS ( SELECT 1
   FROM outfit_suggestions os
  WHERE ((os.id = outfit_suggestion_items.outfit_suggestion_id) AND (os.user_id = auth.uid())))));


create policy "Users can view items of their own outfit suggestions"
on "public"."outfit_suggestion_items"
as permissive
for select
to public
using ((EXISTS ( SELECT 1
   FROM outfit_suggestions os
  WHERE ((os.id = outfit_suggestion_items.outfit_suggestion_id) AND (os.user_id = auth.uid())))));


create policy "Users can delete their own outfit suggestions"
on "public"."outfit_suggestions"
as permissive
for delete
to public
using ((auth.uid() = user_id));


create policy "Users can insert their own outfit suggestions"
on "public"."outfit_suggestions"
as permissive
for insert
to public
with check ((auth.uid() = user_id));


create policy "Users can update their own outfit suggestions"
on "public"."outfit_suggestions"
as permissive
for update
to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view their own outfit suggestions"
on "public"."outfit_suggestions"
as permissive
for select
to public
using ((auth.uid() = user_id));


create policy "Users can insert their own preferences"
on "public"."user_preferences_derived"
as permissive
for insert
to public
with check ((auth.uid() = user_id));


create policy "Users can update their own preferences"
on "public"."user_preferences_derived"
as permissive
for update
to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view their own preferences"
on "public"."user_preferences_derived"
as permissive
for select
to public
using ((auth.uid() = user_id));


create policy "Users can update their own profile"
on "public"."users"
as permissive
for update
to public
using ((auth.uid() = id))
with check ((auth.uid() = id));


create policy "Users can view their own profile"
on "public"."users"
as permissive
for select
to public
using ((auth.uid() = id));


create policy "Users can delete their own wishlist items"
on "public"."wishlist_items"
as permissive
for delete
to public
using ((auth.uid() = user_id));


create policy "Users can insert their own wishlist items"
on "public"."wishlist_items"
as permissive
for insert
to public
with check ((auth.uid() = user_id));


create policy "Users can update their own wishlist items"
on "public"."wishlist_items"
as permissive
for update
to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view their own wishlist items"
on "public"."wishlist_items"
as permissive
for select
to public
using ((auth.uid() = user_id));


CREATE TRIGGER on_ai_shopping_suggestions_updated BEFORE UPDATE ON public.ai_shopping_suggestions FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_garment_items_updated BEFORE UPDATE ON public.garment_items FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_logged_outfit_change_update_preferences AFTER INSERT OR DELETE OR UPDATE ON public.logged_outfits FOR EACH ROW EXECUTE FUNCTION handle_logged_outfit_for_preferences();

CREATE TRIGGER on_logged_outfits_updated BEFORE UPDATE ON public.logged_outfits FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_outfit_suggestions_updated BEFORE UPDATE ON public.outfit_suggestions FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_user_preferences_derived_updated BEFORE UPDATE ON public.user_preferences_derived FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_users_updated BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_wishlist_items_updated BEFORE UPDATE ON public.wishlist_items FOR EACH ROW EXECUTE FUNCTION handle_updated_at();


