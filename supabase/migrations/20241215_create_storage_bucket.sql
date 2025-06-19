-- Create the wardrobe-images storage bucket (private for user security)
insert into storage.buckets (id, name, public)
values ('wardrobe-images', 'wardrobe-images', false);

-- Create policy for authenticated users to upload their own images (path-based security)
create policy "Users can upload their own wardrobe images" on storage.objects
for insert to authenticated
with check (bucket_id = 'wardrobe-images' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Create policy for authenticated users to view their own images
create policy "Users can view their own wardrobe images" on storage.objects
for select to authenticated
using (bucket_id = 'wardrobe-images' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Create policy for authenticated users to update their own images  
create policy "Users can update their own wardrobe images" on storage.objects
for update to authenticated
using (bucket_id = 'wardrobe-images' AND (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'wardrobe-images' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Create policy for authenticated users to delete their own images
create policy "Users can delete their own wardrobe images" on storage.objects
for delete to authenticated
using (bucket_id = 'wardrobe-images' AND (storage.foldername(name))[1] = auth.uid()::text); 