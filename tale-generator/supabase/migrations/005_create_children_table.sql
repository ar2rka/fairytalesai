-- Create children table
CREATE TABLE IF NOT EXISTS tales.children (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER NOT NULL,
    gender TEXT NOT NULL,
    interests TEXT[] NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_children_name ON tales.children(name);
CREATE INDEX IF NOT EXISTS idx_children_age ON tales.children(age);
CREATE INDEX IF NOT EXISTS idx_children_gender ON tales.children(gender);

-- Add child_id column to stories table
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS child_id UUID REFERENCES tales.children(id);

-- Create index for the child_id column
CREATE INDEX IF NOT EXISTS idx_stories_child_id ON tales.stories(child_id);

-- Enable Row Level Security (RLS) for children table
ALTER TABLE tales.children ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated users on children table
-- Note: You may need to adjust these policies based on your security requirements
CREATE POLICY "Enable read access for all users" ON "tales"."children"
AS PERMISSIVE FOR SELECT
TO public
USING (true);

CREATE POLICY "Enable insert access for all users" ON "tales"."children"
AS PERMISSIVE FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Enable update access for all users" ON "tales"."children"
AS PERMISSIVE FOR UPDATE
TO public
USING (true);

CREATE POLICY "Enable delete access for all users" ON "tales"."children"
AS PERMISSIVE FOR DELETE
TO public
USING (true);