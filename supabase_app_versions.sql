-- Create the app_versions table
CREATE TABLE IF NOT EXISTS public.app_versions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    version TEXT NOT NULL,
    build_number INTEGER NOT NULL,
    download_url TEXT NOT NULL,
    release_notes TEXT,
    is_mandatory BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read the versions
CREATE POLICY "Allow public read access to app_versions" 
    ON public.app_versions 
    FOR SELECT 
    USING (true);

-- Insert the initial version (1.0.0+1)
INSERT INTO public.app_versions (version, build_number, download_url, release_notes)
VALUES (
    '1.0.0', 
    1, 
    'https://example.com/download/hopel-1.0.0.apk', 
    'גרסת בסיס'
);
