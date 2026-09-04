USE master;
GO

IF DB_ID('RaceDay') IS NOT NULL
BEGIN
    ALTER DATABASE RaceDay SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDay;
END
GO

CREATE DATABASE RaceDay;
GO

USE RaceDay;
GO

-- 1. Users (both Organiser and Participant)
CREATE TABLE [User] (
    UserId          INT IDENTITY(1,1) PRIMARY KEY,
    Email           NVARCHAR(256) NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(512) NOT NULL,          -- store hashed value only
    FirstName       NVARCHAR(100) NOT NULL,
    LastName        NVARCHAR(100) NOT NULL,
    Role            NVARCHAR(20)  NOT NULL CHECK (Role IN ('Organiser','Participant')),
    CreatedAt       DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    IsActive        BIT           NOT NULL DEFAULT 1
);
GO

-- 2. Events
CREATE TABLE [Event] (
    EventId         INT IDENTITY(1,1) PRIMARY KEY,
    OrganiserId     INT           NOT NULL,
    Name            NVARCHAR(200) NOT NULL,
    Description     NVARCHAR(MAX) NULL,
    EventDate       DATETIME2     NOT NULL,
    Location        NVARCHAR(200) NOT NULL,
    Province        NVARCHAR(50)  NOT NULL,
    Status          NVARCHAR(20)  NOT NULL DEFAULT 'Draft'
                    CHECK (Status IN ('Draft','Published','Completed','Cancelled')),
    MaxParticipants INT           NULL,
    CreatedAt       DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Event_Organiser FOREIGN KEY (OrganiserId) REFERENCES [User](UserId)
);
GO

-- 3. Categories
CREATE TABLE Category (
    CategoryId      INT IDENTITY(1,1) PRIMARY KEY,
    EventId         INT           NOT NULL,
    Name            NVARCHAR(100) NOT NULL,
    DistanceKm      DECIMAL(6,2)  NOT NULL,
    EntryFee        DECIMAL(10,2) NOT NULL DEFAULT 0,
    MaxEntries      INT           NULL,
    AgeMin          INT           NULL,
    AgeMax          INT           NULL,
    CONSTRAINT FK_Category_Event FOREIGN KEY (EventId) REFERENCES [Event](EventId) ON DELETE CASCADE
);
GO

-- 4. Enrolments
CREATE TABLE Enrolment (
    EnrolmentId     INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantId   INT           NOT NULL,
    CategoryId      INT           NOT NULL,
    EnrolmentDate   DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    Status          NVARCHAR(20)  NOT NULL DEFAULT 'Confirmed'
                    CHECK (Status IN ('Pending','Confirmed','Cancelled','DNS','DNF')),
    CONSTRAINT FK_Enrolment_Participant FOREIGN KEY (ParticipantId) REFERENCES [User](UserId),
    CONSTRAINT FK_Enrolment_Category   FOREIGN KEY (CategoryId)   REFERENCES Category(CategoryId),
    CONSTRAINT UQ_Enrolment_Participant_Category UNIQUE (ParticipantId, CategoryId)
);
GO

-- 5. Results
CREATE TABLE Result (
    ResultId        INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentId     INT           NOT NULL UNIQUE,
    FinishTime      TIME(0)       NULL,               -- or INT seconds if preferred
    Position        INT           NULL,
    Status          NVARCHAR(20)  NOT NULL DEFAULT 'Finished'
                    CHECK (Status IN ('Finished','DNF','DNS','DQ')),
    RecordedAt      DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    RecordedBy      INT           NOT NULL,
    CONSTRAINT FK_Result_Enrolment FOREIGN KEY (EnrolmentId) REFERENCES Enrolment(EnrolmentId),
    CONSTRAINT FK_Result_RecordedBy FOREIGN KEY (RecordedBy) REFERENCES [User](UserId)
);
GO

-- Optional: Refresh tokens for JWT (Part 2)
CREATE TABLE RefreshToken (
    TokenId         INT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT           NOT NULL,
    Token           NVARCHAR(512) NOT NULL,
    Expires         DATETIME2     NOT NULL,
    Created         DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    Revoked         DATETIME2     NULL,
    CONSTRAINT FK_RefreshToken_User FOREIGN KEY (UserId) REFERENCES [User](UserId) ON DELETE CASCADE
);
GO

-- Two Organisers
INSERT INTO [User] (Email, PasswordHash, FirstName, LastName, Role)
VALUES 
('thabo.organiser@raceday.co.za', 'AQAAAAEAACcQAAAAEHashedPasswordExample1==', 'Thabo', 'Mokoena', 'Organiser'),
('sarah.organiser@raceday.co.za', 'AQAAAAEAACcQAAAAEHashedPasswordExample2==', 'Sarah', 'van der Berg', 'Organiser');

-- Two Participants
INSERT INTO [User] (Email, PasswordHash, FirstName, LastName, Role)
VALUES 
('lerato.runner@gmail.com', 'AQAAAAEAACcQAAAAEHashedPasswordExample3==', 'Lerato', 'Dlamini', 'Participant'),
('james.cyclist@gmail.com', 'AQAAAAEAACcQAAAAEHashedPasswordExample4==', 'James', 'Ndlovu', 'Participant');

-- Three Events
INSERT INTO [Event] (OrganiserId, Name, Description, EventDate, Location, Province, Status, MaxParticipants)
VALUES
(1, 'Soweto Marathon 2026', 'Iconic 42.2 km race through the streets of Soweto.', '2026-11-01 06:00:00', 'FNB Stadium, Johannesburg', 'Gauteng', 'Published', 15000),
(1, 'Cape Town Cycle Tour Training Ride', 'Community 50 km training ride for the Cycle Tour.', '2026-02-15 07:00:00', 'Sea Point Promenade', 'Western Cape', 'Published', 500),
(2, 'Two Oceans Half Marathon Prep', '21.1 km preparation event on the Two Oceans route.', '2026-03-20 06:30:00', 'UCT Sports Fields, Cape Town', 'Western Cape', 'Published', 3000);

-- Categories for each event
INSERT INTO Category (EventId, Name, DistanceKm, EntryFee, MaxEntries)
VALUES
(1, '42.2 km Marathon', 42.20, 450.00, 10000),
(1, '21.1 km Half Marathon', 21.10, 350.00, 5000),
(2, '50 km Cycle', 50.00, 150.00, 500),
(3, '21.1 km Half', 21.10, 280.00, 3000),
(3, '10 km Fun Run', 10.00, 150.00, 1000);

-- Sample enrolments
INSERT INTO Enrolment (ParticipantId, CategoryId, Status)
VALUES
(3, 1, 'Confirmed'),   -- Lerato into Soweto Marathon
(3, 4, 'Confirmed'),   -- Lerato into Two Oceans Half
(4, 3, 'Confirmed');   -- James into Cycle Tour training

-- Sample result
INSERT INTO Result (EnrolmentId, FinishTime, Position, Status, RecordedBy)
VALUES
(1, '03:45:22', 1250, 'Finished', 1);

PRINT 'RaceDay schema and seed data created successfully.';
GO
