-- Create function to handle new user creation in public.users
-- This function is triggered when a new user signs up via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER -- Required to access auth.users
AS $$
BEGIN
  -- Insert new user profile into public.users
  -- All NOT NULL columns either have defaults or are provided
  INSERT INTO public.users (
    id,
    created_at,
    updated_at,
    location_permission_granted,
    calendar_permission_granted
  )
  VALUES (
    NEW.id,
    NOW(),
    NOW(),
    false, -- Default location permission to false
    false  -- Default calendar permission to false
  );
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists (for safe reapplication)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger to call the function after a new user signs up
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user(); 