    CREATE SCHEMA IF NOT EXISTS tales;  
    -- Create stories table
    CREATE TABLE IF NOT EXISTS tales.stories (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        moral TEXT NOT NULL,
        child_name TEXT NOT NULL,
        child_age INTEGER NOT NULL,
        child_gender TEXT NOT NULL,
        child_interests TEXT[] NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Create indexes for better query performance
    CREATE INDEX IF NOT EXISTS idx_stories_child_name ON tales.stories(child_name);
    CREATE INDEX IF NOT EXISTS idx_stories_created_at ON tales.stories(created_at);
    CREATE INDEX IF NOT EXISTS idx_stories_moral ON tales.stories(moral);

    -- Enable Row Level Security (RLS)
    ALTER TABLE stories ENABLE ROW LEVEL SECURITY;

    -- Create policies for authenticated users
    -- Note: You may need to adjust these policies based on your security requirements
    CREATE POLICY "Enable read access for all users" ON "tales"."stories"
    AS PERMISSIVE FOR SELECT
    TO public
    USING (true);

    CREATE POLICY "Enable insert access for all users" ON "tales"."stories"
    AS PERMISSIVE FOR INSERT
    TO public
    WITH CHECK (true);

    CREATE POLICY "Enable update access for all users" ON "tales"."stories"
    AS PERMISSIVE FOR UPDATE
    TO public
    USING (true);

    CREATE POLICY "Enable delete access for all users" ON "tales"."stories"
    AS PERMISSIVE FOR DELETE
    TO public
    USING (true);