-- Create Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enum Types
CREATE TYPE role_type AS ENUM (
    'ADMIN',
    'RECRUITER',
    'ENTREPRENEUR', 
    'CANDIDATE'
);

CREATE TYPE company_size AS ENUM (
    'STARTUP',
    'SMALL',
    'MEDIUM', 
    'LARGE',
    'ENTERPRISE'
);

CREATE TYPE job_contract_type AS ENUM (
    'FULL_TIME',
    'PART_TIME',
    'CONTRACT',
    'FREELANCE',
    'INTERNSHIP',
    'TEMPORARY'
);

CREATE TYPE workplace_type AS ENUM (
    'ONSITE',
    'HYBRID', 
    'REMOTE',
    'ON_THE_ROAD'
);

CREATE TYPE job_status AS ENUM (
    'OPEN',
    'CLOSED',
    'PAUSED',
    'DRAFT'
);

CREATE TYPE employment_status AS ENUM (
    'EMPLOYED',
    'NOT_EMPLOYED',
    'SELF_EMPLOYED',
    'STUDENT'
);

CREATE TYPE experience_level AS ENUM (
    'ENTRY',
    'JUNIOR', 
    'MID',
    'SENIOR',
    'LEAD',
    'EXPERT'
);

CREATE TYPE interview_type AS ENUM (
    'PHONE_SCREENING',
    'ONLINE_INTERVIEW',
    'DESIGN_TEST', 
    'IN_PERSON',
    'AUTOMATED_VIDEO',
    'TECHNICAL_ASSESSMENT', 
    'CULTURAL_FIT',
    'ASSIGNMENT', 
    'PORTFOLIO_PRESENTATION'
);

CREATE TYPE benefit_type AS ENUM (
    'HEALTH_INSURANCE',
    'DENTAL_INSURANCE',
    'VISION_INSURANCE',
    'RETIREMENT_PLAN',
    'STOCK_OPTIONS',
    'FLEXIBLE_HOURS',
    'REMOTE_WORK',
    'VACATION_TIME',
    'PARENTAL_LEAVE',
    'PROFESSIONAL_DEVELOPMENT'
);

CREATE TYPE application_status AS ENUM (
    'IN_REVIEW',
    'SHORTLISTED',
    'INTERVIEW_SCHEDULED',
    'TECHNICAL_ASSESSMENT',
    'REFERENCE_CHECK', 
    'OFFER_SENT',
    'ACCEPTED',
    'REFUSED',
    'WITHDRAWN'
);

CREATE TYPE activity_status AS ENUM (
    'APPLIED',
    'SAVED', 
    'INTERVIEWED',
    'ARCHIVED'
);

CREATE TYPE notification_type AS ENUM (
    'JOB_APPLIED',
    'APPLICATION_UPDATE', 
    'INTERVIEW_INVITATION',
    'JOB_MATCH',
    'PROFILE_VIEW',
    'SYSTEM'
);

CREATE TYPE applicant_type AS ENUM (
    'CANDIDATE',
    'ENTREPRENEUR'
);

CREATE TYPE resume_owner_type AS ENUM (
    'CANDIDATE',
    'ENTREPRENEUR'
);

-- User Profiles Table (links to auth.users)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role role_type NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    profile_picture_url TEXT,
    bio TEXT,
    location VARCHAR(255),
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Companies Table
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    founded_year INTEGER,
    logo_url TEXT,
    location VARCHAR(255),
    company_size company_size NOT NULL,
    industry VARCHAR(255),
    description TEXT,
    website VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Recruiters Table
CREATE TABLE recruiters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    profile_id UUID UNIQUE NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    company_id UUID REFERENCES companies(id) NOT NULL,
    position VARCHAR(255),
    years_of_experience INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Entrepreneurs Table
CREATE TABLE entrepreneurs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    profile_id UUID UNIQUE NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    business_name VARCHAR(255),
    industry VARCHAR(255),
    skills TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Candidates Table
CREATE TABLE candidates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    profile_id UUID UNIQUE NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    employment_status employment_status NOT NULL,
    education VARCHAR(255),
    university VARCHAR(255),
    current_job_title VARCHAR(255),
    preferred_company_culture VARCHAR(255),
    minimum_salary NUMERIC(10,2),
    interests TEXT,
    skills TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Jobs Table
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
    salary_min NUMERIC(10,2),
    salary_max NUMERIC(10,2),
    status job_status DEFAULT 'OPEN',
    application_deadline DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Enforce either company job (via recruiter) or entrepreneur job
    CONSTRAINT job_poster_check CHECK (
        (company_id IS NOT NULL AND recruiter_id IS NOT NULL AND entrepreneur_id IS NULL) OR
        (company_id IS NULL AND recruiter_id IS NULL AND entrepreneur_id IS NOT NULL)
    )
);

-- Job Requirements Table
CREATE TABLE job_requirements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    skill VARCHAR(255) NOT NULL,
    experience_level experience_level,
    is_required BOOLEAN DEFAULT TRUE,
    UNIQUE(job_id, skill)
);

-- Unified Resumes Table (for both candidates and entrepreneurs)
CREATE TABLE resumes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID REFERENCES candidates(id) ON DELETE CASCADE,
    entrepreneur_id UUID REFERENCES entrepreneurs(id) ON DELETE CASCADE,
    owner_type resume_owner_type NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Ensure only one owner type is specified
    CONSTRAINT resume_owner_check CHECK (
        (candidate_id IS NOT NULL AND entrepreneur_id IS NULL AND owner_type = 'CANDIDATE') OR
        (entrepreneur_id IS NOT NULL AND candidate_id IS NULL AND owner_type = 'ENTREPRENEUR')
    )
);

-- Applications Table
CREATE TABLE applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    candidate_id UUID REFERENCES candidates(id) ON DELETE CASCADE,
    entrepreneur_id UUID REFERENCES entrepreneurs(id) ON DELETE CASCADE,
    resume_id UUID REFERENCES resumes(id),
    applicant_type applicant_type NOT NULL,
    status application_status DEFAULT 'IN_REVIEW',
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Either candidate OR entrepreneur must apply (not both)
    CONSTRAINT applicant_check CHECK (
        (candidate_id IS NOT NULL AND entrepreneur_id IS NULL AND applicant_type = 'CANDIDATE') OR
        (entrepreneur_id IS NOT NULL AND candidate_id IS NULL AND applicant_type = 'ENTREPRENEUR')
    ),
    -- Ensure uniqueness of applications per job per applicant
    CONSTRAINT unique_candidate_application UNIQUE (job_id, candidate_id),
    CONSTRAINT unique_entrepreneur_application UNIQUE (job_id, entrepreneur_id)
);

-- Activity Tracking
CREATE TABLE user_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    status activity_status NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    UNIQUE(user_id, job_id, status)
);

-- Notifications Table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    related_entity_id UUID,
    related_entity_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- RLS Policies
-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE recruiters ENABLE ROW LEVEL SECURITY;
ALTER TABLE entrepreneurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create basic policies (example)
CREATE POLICY "Users can view their own profile"
    ON user_profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile"
    ON user_profiles FOR UPDATE
    USING (auth.uid() = user_id);

-- Indexes for Performance Optimization
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_company ON jobs(company_id);
CREATE INDEX idx_jobs_entrepreneur ON jobs(entrepreneur_id);
CREATE INDEX idx_applications_status ON applications(status);
CREATE INDEX idx_applications_candidate ON applications(candidate_id);
CREATE INDEX idx_applications_entrepreneur ON applications(entrepreneur_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_user_activities_user ON user_activities(user_id);
CREATE INDEX idx_entrepreneurs_skills ON entrepreneurs USING gin(skills);
CREATE INDEX idx_candidates_skills ON candidates USING gin(skills);
CREATE INDEX idx_resumes_candidate ON resumes(candidate_id);
CREATE INDEX idx_resumes_entrepreneur ON resumes(entrepreneur_id);