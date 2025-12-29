export interface ChildProfile {
  id: string;
  name: string;
  age_category: string; // Age category: '2-3', '3-5', or '5-7'
  age?: number; // Calculated from category, for backward compatibility
  gender: string;
  interests: string[];
  created_at: string;
  updated_at: string;
}

export interface Story {
  id: string;
  title: string;
  content: string;
  moral: string;
  language: string;
  story_type: string;
  child_id?: string | null;
  child_name: string | null;
  child_age: number | null;
  child_gender: string | null;
  child_interests: string[] | null;
  hero_id?: string | null;
  hero_name: string | null;
  hero_gender: string | null;
  hero_appearance: string | null;
  relationship_description: string | null;
  parent_id?: string | null;
  created_at: string;
  updated_at: string;
  story_length: number | null;
  rating: number | null;
  audio_file_url: string | null;
  audio_provider?: string | null;
  model_used: string | null;
  status: string;
  user_id?: string | null;
}

export interface Hero {
  id: string;
  name: string;
  gender: string;
  appearance: string;
  personality_traits: string[];
  interests: string[];
  strengths: string[];
  language: string;
  user_id: string | null;
  created_at: string;
  updated_at: string;
}
