-- Generated schema.sql based on Supabase migrations
-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";
-- Create auth schema if not exists (standard in Supabase)
CREATE SCHEMA IF NOT EXISTS auth;
-- Auth Users Table (Standard Supabase auth.users)
CREATE TABLE IF NOT EXISTS auth.users (
    instance_id uuid,
    id uuid NOT NULL PRIMARY KEY,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone character varying(15) DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change character varying(15) DEFAULT NULL::character varying,
    phone_change_token character varying(255) DEFAULT NULL::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone,
    email_change_token_current character varying(255) DEFAULT NULL::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT NULL::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone
);
CREATE INDEX IF NOT EXISTS users_instance_id_idx ON auth.users USING btree (instance_id);
CREATE INDEX IF NOT EXISTS users_email_idx ON auth.users USING btree (email);
-- Enum Types
CREATE TYPE role_type AS ENUM ('ADMIN', 'RECRUITER', 'ENTREPRENEUR', 'CANDIDATE');
CREATE TYPE employment_status AS ENUM ('EMPLOYED', 'UNEMPLOYED', 'FREELANCE', 'STUDENT', 'INTERNSHIP');
CREATE TYPE resume_owner_type AS ENUM ('CANDIDATE', 'ENTREPRENEUR');
CREATE TYPE job_contract_type AS ENUM ('FULL_TIME', 'PART_TIME', 'CONTRACT', 'FREELANCE', 'INTERNSHIP', 'TEMPORARY');
CREATE TYPE workplace_type AS ENUM ('ONSITE', 'HYBRID', 'REMOTE', 'ON_THE_ROAD');
CREATE TYPE job_status AS ENUM ('OPEN', 'CLOSED', 'PAUSED', 'DRAFT');
CREATE TYPE experience_level AS ENUM ('ENTRY', 'JUNIOR', 'MID', 'SENIOR', 'LEAD', 'EXPERT');
CREATE TYPE education_level AS ENUM ('HIGH_SCHOOL_DIPLOMA', 'BACHELOR', 'LICENSE', 'MASTERS', 'MBA', 'PHD', 'OTHER');
CREATE TYPE application_status AS ENUM ('IN_REVIEW', 'SHORTLISTED', 'INTERVIEW_SCHEDULED', 'TECHNICAL_ASSESSMENT', 'REFERENCE_CHECK', 'OFFER_SENT', 'ACCEPTED', 'REFUSED', 'WITHDRAWN');
CREATE TYPE applicant_type AS ENUM ('CANDIDATE', 'ENTREPRENEUR');
CREATE TYPE activity_type AS ENUM ('SAVED_JOB', 'VIEWED_JOB', 'APPLIED_TO_JOB', 'WITHDREW_APPLICATION', 'UPDATED_PROFILE', 'UPLOADED_RESUME', 'FOLLOWED_COMPANY', 'SHARED_JOB');
CREATE TYPE notification_type AS ENUM ('APPLICATION_STATUS_CHANGED', 'JOB_VIEWED', 'PROFILE_UPDATED', 'RESUME_UPLOADED', 'JOB_SAVED', 'COMPANY_FOLLOWED', 'INTERVIEW_SCHEDULED', 'OFFER_RECEIVED', 'REMINDER');
-- Tables
-- user_profiles
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role role_type,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    profile_picture_url TEXT,
    bio TEXT,
    location VARCHAR(500),
    phone VARCHAR(50),
    email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- companies
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    founded_year INTEGER,
    logo_url TEXT,
    location TEXT,
    company_size TEXT,
    industry TEXT,
    description TEXT,
    mission TEXT,
    team_description TEXT,
    unique_journey TEXT,
    employee_expectations TEXT,
    website TEXT,
    company_email TEXT,
    office_branches TEXT,
    office_locations TEXT[],
    cultural_values TEXT[],
    interview_methods TEXT[],
    culture_ratings JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
-- recruiters
CREATE TABLE recruiters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    position TEXT,
    years_of_experience INTEGER,
    hiring_goals TEXT,
    interview_preferences TEXT[],
    recruiting_focus TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
-- entrepreneurs
CREATE TABLE entrepreneurs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    profile_id UUID UNIQUE NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    business_name VARCHAR(255),
    industry VARCHAR(255),
    skills TEXT[],
    current_position VARCHAR(255),
    business_description TEXT,
    business_size VARCHAR(50),
    founded_year INTEGER,
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- candidates
CREATE TABLE candidates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    profile_id UUID UNIQUE NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    employment_status employment_status NOT NULL,
    education VARCHAR(500),
    university VARCHAR(500),
    current_job_title VARCHAR(500),
    preferred_company_culture VARCHAR(500),
    minimum_salary NUMERIC(10,2),
    interests TEXT,
    skills TEXT[],
    preferred_work_location VARCHAR(255),
    willing_to_relocate BOOLEAN DEFAULT false,
    maximum_salary NUMERIC(10,2),
    salary_negotiable BOOLEAN DEFAULT false,
    currency VARCHAR(10) DEFAULT 'ZAR',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- resumes
CREATE TABLE resumes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID REFERENCES candidates(id) ON DELETE CASCADE,
    entrepreneur_id UUID REFERENCES entrepreneurs(id) ON DELETE CASCADE,
    owner_type resume_owner_type NOT NULL,
    title VARCHAR(255),
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER,
    file_type VARCHAR(100),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT resume_owner_check CHECK (
        (candidate_id IS NOT NULL AND entrepreneur_id IS NULL AND owner_type = 'CANDIDATE') OR
        (entrepreneur_id IS NOT NULL AND candidate_id IS NULL AND owner_type = 'ENTREPRENEUR')
    )
);
-- jobs
CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    company_id UUID REFERENCES companies(id),
    recruiter_id UUID REFERENCES recruiters(id),
    entrepreneur_id UUID REFERENCES entrepreneurs(id),
    job_type job_contract_type NOT NULL,
    workplace_type workplace_type NOT NULL,
    location VARCHAR(255),
    category VARCHAR(100),
    salary_min NUMERIC(10,2),
    salary_max NUMERIC(10,2),
    status job_status DEFAULT 'OPEN',
    application_deadline DATE,
    is_easy_apply BOOLEAN DEFAULT false,
    views INTEGER DEFAULT 0,
    requires_portfolio BOOLEAN DEFAULT false,
    requires_cover_letter BOOLEAN DEFAULT false,
    requires_video_presentation BOOLEAN DEFAULT false,
    unique_journey TEXT,
    bring_to_company TEXT,
    team_description TEXT,
    employee_expectations TEXT[],
    recruitment_methods TEXT[],
    benefits TEXT,
    offers TEXT[],
    payment_frequency VARCHAR(50),
    education_level education_level,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT job_poster_check CHECK (
        (company_id IS NOT NULL AND recruiter_id IS NOT NULL AND entrepreneur_id IS NULL) OR
        (company_id IS NOT NULL AND recruiter_id IS NULL AND entrepreneur_id IS NULL) OR
        (company_id IS NULL AND recruiter_id IS NULL AND entrepreneur_id IS NOT NULL)
    )
);
-- job_requirements
CREATE TABLE job_requirements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    skill VARCHAR(255) NOT NULL,
    experience_level experience_level,
    is_required BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(job_id, skill)
);
-- job_views
CREATE TABLE job_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    ip_address INET,
    user_agent TEXT,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(job_id, user_id)
);
-- applications
CREATE TABLE applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    candidate_id UUID REFERENCES candidates(id) ON DELETE CASCADE,
    entrepreneur_id UUID REFERENCES entrepreneurs(id) ON DELETE CASCADE,
    resume_id UUID REFERENCES resumes(id),
    applicant_type applicant_type NOT NULL,
    status application_status DEFAULT 'IN_REVIEW',
    cover_letter TEXT,
    portfolio_url TEXT,
    cover_letter_path TEXT,
    video_presentation_path TEXT,
    additional_files TEXT[],
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT applicant_check CHECK (
        (candidate_id IS NOT NULL AND entrepreneur_id IS NULL AND applicant_type = 'CANDIDATE') OR
        (entrepreneur_id IS NOT NULL AND candidate_id IS NULL AND applicant_type = 'ENTREPRENEUR')
    ),
    CONSTRAINT unique_candidate_application UNIQUE (job_id, candidate_id),
    CONSTRAINT unique_entrepreneur_application UNIQUE (job_id, entrepreneur_id)
);
-- user_activities
CREATE TABLE user_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    activity_type activity_type NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_job_activity UNIQUE (user_id, job_id, activity_type)
);
-- notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    related_entity_id UUID,
    related_entity_type VARCHAR(50),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP,
    CONSTRAINT idx_notifications_user_read UNIQUE (user_id, id)
);
-- Indexes
CREATE INDEX idx_entrepreneurs_industry ON entrepreneurs USING btree (industry);
CREATE INDEX idx_entrepreneurs_profile_id ON entrepreneurs USING btree (profile_id);
CREATE INDEX idx_entrepreneurs_skills ON entrepreneurs USING gin (skills);
CREATE INDEX idx_entrepreneurs_user_id ON entrepreneurs USING btree (user_id);
CREATE INDEX idx_entrepreneurs_company_id ON entrepreneurs USING btree (company_id);
CREATE INDEX idx_user_profiles_email ON user_profiles USING btree (email);
CREATE INDEX idx_resumes_candidate ON resumes USING btree (candidate_id);
CREATE INDEX idx_resumes_entrepreneur ON resumes USING btree (entrepreneur_id);
CREATE INDEX idx_resumes_is_default ON resumes USING btree (is_default);
CREATE INDEX idx_resumes_owner_type ON resumes USING btree (owner_type);
CREATE INDEX idx_recruiters_company_id ON recruiters(company_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_company ON jobs(company_id);
CREATE INDEX idx_jobs_recruiter ON jobs(recruiter_id);
CREATE INDEX idx_jobs_entrepreneur ON jobs(entrepreneur_id);
CREATE INDEX idx_jobs_category ON jobs(category);
CREATE INDEX idx_jobs_easy_apply ON jobs(is_easy_apply);
CREATE INDEX idx_jobs_views ON jobs(views);
CREATE INDEX idx_jobs_created_at ON jobs(created_at);
CREATE INDEX idx_jobs_location ON jobs(location);
CREATE INDEX idx_job_requirements_job_id ON job_requirements(job_id);
CREATE INDEX idx_job_views_job_id ON job_views(job_id);
CREATE INDEX idx_job_views_user_id ON job_views(user_id);
CREATE INDEX idx_jobs_education_level ON jobs(education_level);
CREATE INDEX idx_jobs_requires_portfolio ON jobs(requires_portfolio) WHERE requires_portfolio = true;
CREATE INDEX idx_jobs_requires_cover_letter ON jobs(requires_cover_letter) WHERE requires_cover_letter = true;
CREATE INDEX idx_jobs_requires_video_presentation ON jobs(requires_video_presentation) WHERE requires_video_presentation = true;
CREATE INDEX idx_applications_job_id ON applications(job_id);
CREATE INDEX idx_applications_candidate_id ON applications(candidate_id);
CREATE INDEX idx_applications_entrepreneur_id ON applications(entrepreneur_id);
CREATE INDEX idx_applications_status ON applications(status);
CREATE INDEX idx_applications_applied_at ON applications(applied_at);
CREATE INDEX idx_applications_applicant_type ON applications(applicant_type);
CREATE INDEX idx_applications_portfolio_url ON applications(portfolio_url) WHERE portfolio_url IS NOT NULL;
CREATE INDEX idx_applications_cover_letter_path ON applications(cover_letter_path) WHERE cover_letter_path IS NOT NULL;
CREATE INDEX idx_applications_video_presentation_path ON applications(video_presentation_path) WHERE video_presentation_path IS NOT NULL;
CREATE INDEX idx_user_activities_user_id ON user_activities(user_id);
CREATE INDEX idx_user_activities_job_id ON user_activities(job_id);
CREATE INDEX idx_user_activities_activity_type ON user_activities(activity_type);
CREATE INDEX idx_user_activities_created_at ON user_activities(created_at);
CREATE INDEX idx_user_activities_user_job ON user_activities(user_id, job_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_related_entity ON notifications(related_entity_type, related_entity_id);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
-- Functions & Triggers
-- handle_new_user
CREATE OR REPLACE FUNCTION handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.user_profiles (user_id)
  VALUES (new.id); -- Don't assign a default role, let user select it
  RETURN new;
END;
$$;
-- set_default_resume
CREATE OR REPLACE FUNCTION set_default_resume() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  -- If this is the first resume for this owner, make it default
  IF NEW.owner_type = 'CANDIDATE' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.resumes 
      WHERE candidate_id = NEW.candidate_id 
      AND id != NEW.id
    ) THEN
      NEW.is_default = TRUE;
    END IF;
  ELSIF NEW.owner_type = 'ENTREPRENEUR' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.resumes 
      WHERE entrepreneur_id = NEW.entrepreneur_id 
      AND id != NEW.id
    ) THEN
      NEW.is_default = TRUE;
    END IF;
  END IF;
  
  -- If setting this as default, remove default from others
  IF NEW.is_default = TRUE THEN
    IF NEW.owner_type = 'CANDIDATE' THEN
      UPDATE public.resumes 
      SET is_default = FALSE 
      WHERE candidate_id = NEW.candidate_id 
      AND id != NEW.id;
    ELSIF NEW.owner_type = 'ENTREPRENEUR' THEN
      UPDATE public.resumes 
      SET is_default = FALSE 
      WHERE entrepreneur_id = NEW.entrepreneur_id 
      AND id != NEW.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;
-- handle_updated_at
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- track_job_view
CREATE OR REPLACE FUNCTION track_job_view(job_uuid UUID, user_uuid UUID DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    view_inserted BOOLEAN := FALSE;
BEGIN
    -- Try to insert view record, only increment if it's a new view
    INSERT INTO public.job_views (job_id, user_id)
    VALUES (job_uuid, user_uuid)
    ON CONFLICT (job_id, user_id) DO NOTHING
    RETURNING TRUE INTO view_inserted;
    
    -- Only increment job views counter if a new view was actually inserted
    IF view_inserted THEN
        UPDATE public.jobs 
        SET views = views + 1, updated_at = CURRENT_TIMESTAMP
        WHERE id = job_uuid;
    END IF;
END;
$$;
-- notify_application_status_change
CREATE OR REPLACE FUNCTION notify_application_status_change()
RETURNS TRIGGER AS $$
DECLARE
    job_title VARCHAR(255);
    applicant_user_id UUID;
BEGIN
    -- Only proceed if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        -- Get job title
        SELECT title INTO job_title FROM jobs WHERE id = NEW.job_id;
        
        -- Get applicant user_id (candidate or entrepreneur)
        IF NEW.candidate_id IS NOT NULL THEN
            SELECT user_id INTO applicant_user_id FROM candidates WHERE id = NEW.candidate_id;
        ELSIF NEW.entrepreneur_id IS NOT NULL THEN
            SELECT user_id INTO applicant_user_id FROM entrepreneurs WHERE id = NEW.entrepreneur_id;
        END IF;
        
        -- Create notification for applicant only
        IF applicant_user_id IS NOT NULL THEN
            INSERT INTO notifications (user_id, type, title, message, related_entity_id, related_entity_type, metadata)
            VALUES (
                applicant_user_id,
                'APPLICATION_STATUS_CHANGED',
                'Application Status Updated',
                'Your application for "' || job_title || '" has been updated to ' || NEW.status,
                NEW.id,
                'application',
                jsonb_build_object('old_status', OLD.status, 'new_status', NEW.status, 'job_title', job_title, 'job_id', NEW.job_id)
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Triggers
CREATE TRIGGER set_default_resume_trigger BEFORE INSERT OR UPDATE ON resumes FOR EACH ROW EXECUTE FUNCTION set_default_resume();
CREATE TRIGGER companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE FUNCTION handle_updated_at();
CREATE TRIGGER recruiters_updated_at BEFORE UPDATE ON recruiters FOR EACH ROW EXECUTE FUNCTION handle_updated_at();
CREATE TRIGGER jobs_updated_at BEFORE UPDATE ON jobs FOR EACH ROW EXECUTE FUNCTION handle_updated_at();
CREATE TRIGGER job_requirements_updated_at BEFORE UPDATE ON job_requirements FOR EACH ROW EXECUTE FUNCTION handle_updated_at();
CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications FOR EACH ROW EXECUTE FUNCTION handle_updated_at();
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';
CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trigger_notify_application_status_change AFTER UPDATE ON applications FOR EACH ROW EXECUTE FUNCTION notify_application_status_change();
-- RLS Policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE recruiters ENABLE ROW LEVEL SECURITY;
ALTER TABLE entrepreneurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
-- Storage Buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('images', 'images', true, 5242880, ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/gif', 'image/svg+xml'])
ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('resumes', 'resumes', false, 10485760, ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('documents', 'documents', false, 20971520, ARRAY[
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/zip',
  'application/x-zip-compressed',
  'application/x-zip',
  'application/x-rar-compressed',
  'application/vnd.rar',
  'application/x-rar',
  'application/rar',
  'application/x-compressed',
  'application/octet-stream',
  'application/x-7z-compressed',
  'image/png',
  'image/jpeg',
  'image/jpg'
])
ON CONFLICT (id) DO UPDATE SET allowed_mime_types = EXCLUDED.allowed_mime_types;
