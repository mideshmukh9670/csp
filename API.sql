-- =============================================
-- Database
-- =============================================
CREATE DATABASE aixm_validator;
GO

USE aixm_validator;
GO

-- =============================================
-- Environment Master
-- =============================================
CREATE TABLE EnvironmentMaster
(
    EnvironmentId INT IDENTITY(1,1) PRIMARY KEY,
    EnvironmentName NVARCHAR(20) NOT NULL UNIQUE,
    BaseUrl NVARCHAR(250),
    IsActive BIT NOT NULL DEFAULT(1),
    CreatedOn DATETIME2 NOT NULL DEFAULT(GETDATE())
);
GO

-- =============================================
-- API Clients
-- =============================================
CREATE TABLE ApiClient
(
    ClientId INT IDENTITY(1,1) PRIMARY KEY,

    ClientName NVARCHAR(100) NOT NULL,

    CompanyName NVARCHAR(150),

    ContactEmail NVARCHAR(150),

    ApiKey NVARCHAR(255) NOT NULL UNIQUE,

    EnvironmentId INT NOT NULL,

    IsActive BIT NOT NULL DEFAULT(1),

    CreatedOn DATETIME2 NOT NULL DEFAULT(GETDATE()),

    ExpiryDate DATETIME2 NULL,

    CONSTRAINT FK_ApiClient_Environment
        FOREIGN KEY(EnvironmentId)
        REFERENCES EnvironmentMaster(EnvironmentId)
);
GO

-- =============================================
-- XSD Version
-- =============================================
CREATE TABLE XSDVersion
(
    XSDId INT IDENTITY(1,1) PRIMARY KEY,

    EnvironmentId INT NOT NULL,

    VersionName NVARCHAR(50) NOT NULL,

    Namespace NVARCHAR(300),

    XSDPath NVARCHAR(500),

    IsActive BIT NOT NULL DEFAULT(1),

    CreatedOn DATETIME2 NOT NULL DEFAULT(GETDATE()),

    CONSTRAINT FK_XSDVersion_Environment
        FOREIGN KEY(EnvironmentId)
        REFERENCES EnvironmentMaster(EnvironmentId)
);
GO

-- =============================================
-- Validation Requests
-- =============================================
CREATE TABLE ValidationRequest
(
    RequestId BIGINT IDENTITY(1,1) PRIMARY KEY,

    ClientId INT NOT NULL,

    XMLFileName NVARCHAR(250),

    ValidationStatus NVARCHAR(20) NOT NULL,

    ExecutionTimeMs INT,

    RequestDate DATETIME2 NOT NULL DEFAULT(GETDATE()),

    CONSTRAINT FK_ValidationRequest_Client
        FOREIGN KEY(ClientId)
        REFERENCES ApiClient(ClientId)
);
GO

-- =============================================
-- Validation Errors
-- =============================================
CREATE TABLE ValidationError
(
    ErrorId BIGINT IDENTITY(1,1) PRIMARY KEY,

    RequestId BIGINT NOT NULL,

    LineNumber INT,

    ErrorMessage NVARCHAR(MAX),

    CONSTRAINT FK_ValidationError_Request
        FOREIGN KEY(RequestId)
        REFERENCES ValidationRequest(RequestId)
        ON DELETE CASCADE
);
GO

-- =============================================
-- API Access Log
-- =============================================
CREATE TABLE ApiAccessLog
(
    LogId BIGINT IDENTITY(1,1) PRIMARY KEY,

    ClientId INT NULL,

    Endpoint NVARCHAR(100),

    HttpMethod NVARCHAR(20),

    IPAddress NVARCHAR(50),

    ResponseCode INT,

    AccessTime DATETIME2 NOT NULL DEFAULT(GETDATE()),

    CONSTRAINT FK_AccessLog_Client
        FOREIGN KEY(ClientId)
        REFERENCES ApiClient(ClientId)
);
GO

-- =============================================
-- Insert Environments
-- =============================================
INSERT INTO EnvironmentMaster
(
    EnvironmentName,
    BaseUrl
)
VALUES
('UAT','https://uat-api.company.com'),
('PROD','https://api.company.com');
GO

-- =============================================
-- Sample API Clients
-- =============================================
INSERT INTO ApiClient
(
    ClientName,
    CompanyName,
    ContactEmail,
    ApiKey,
    EnvironmentId
)
VALUES
(
    'QA Team',
    'ABC Aviation',
    'qa@company.com',
    'uat-secret-key',
    1
),
(
    'AIS Production',
    'ABC Aviation',
    'support@company.com',
    'prod-secret-key',
    2
);
GO

-- =============================================
-- Sample XSD Versions
-- =============================================
INSERT INTO XSDVersion
(
    EnvironmentId,
    VersionName,
    Namespace,
    XSDPath
)
VALUES
(
    1,
    'AIXM 5.1',
    'http://www.aixm.aero/schema/5.1/message',
    'xsd\\uat\\AIXM_BasicMessage.xsd'
),
(
    2,
    'AIXM 5.1',
    'http://www.aixm.aero/schema/5.1/message',
    'xsd\\prod\\AIXM_BasicMessage.xsd'
);
GO