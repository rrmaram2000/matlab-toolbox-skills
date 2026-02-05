# PACS Server Integration

PACS (Picture Archiving and Communication System) stores and distributes medical images in hospitals. MATLAB can connect to PACS servers to query, retrieve, and store DICOM images.

## Key Functions

| Function | Purpose |
|----------|---------|
| `dicomConnection` | Create connection to PACS |
| `dicomquery` | Search for studies/series/images |
| `dicomget` | Retrieve images from PACS |
| `dicomstore` | Send images to PACS |

## Connection Setup

### Create Connection

```matlab
% Basic connection
conn = dicomConnection('192.168.1.100', 4006);

% With calling AE title
conn = dicomConnection('192.168.1.100', 4006, ...
    'CallingAETitle', 'MATLAB_CLIENT');

% With called AE title (PACS identifier)
conn = dicomConnection('192.168.1.100', 4006, ...
    'CallingAETitle', 'MATLAB_CLIENT', ...
    'CalledAETitle', 'PACS_SERVER');
```

### Connection Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| Host | PACS server IP/hostname | '192.168.1.100' |
| Port | DICOM port (typically 104 or 4006) | 4006 |
| CallingAETitle | Your application's identifier | 'MATLAB' |
| CalledAETitle | PACS server's identifier | 'DCM4CHEE' |

### Verify Connection

```matlab
conn = dicomConnection('192.168.1.100', 4006);

% Test with C-ECHO
try
    echo(conn);
    fprintf('Connection successful!\n');
catch ME
    fprintf('Connection failed: %s\n', ME.message);
end
```

## Querying PACS

### Query Levels

| Level | Returns | Use Case |
|-------|---------|----------|
| `'Patient'` | Patient records | Find all patients |
| `'Study'` | Studies for patient(s) | Find exams |
| `'Series'` | Series within study | Find specific scan |
| `'Image'` | Individual images | Find specific slice |

### Query for Studies

```matlab
conn = dicomConnection('pacs.hospital.org', 4006);

% Find all studies for a patient
results = dicomquery(conn, 'Study', ...
    'PatientID', 'PAT001');

% Display results
disp(results);
% Shows: StudyInstanceUID, StudyDate, StudyDescription, etc.
```

### Query with Filters

```matlab
% Find CT studies from date range
results = dicomquery(conn, 'Study', ...
    'Modality', 'CT', ...
    'StudyDate', '20240101-20240331');  % Date range

% Find MRI brain studies
results = dicomquery(conn, 'Study', ...
    'Modality', 'MR', ...
    'StudyDescription', '*BRAIN*');  % Wildcard

% Find studies by referring physician
results = dicomquery(conn, 'Study', ...
    'ReferringPhysicianName', 'Smith*');
```

### Query for Series

```matlab
% First, find study
studies = dicomquery(conn, 'Study', 'PatientID', 'PAT001');

% Then find series within study
studyUID = studies.StudyInstanceUID{1};
series = dicomquery(conn, 'Series', ...
    'StudyInstanceUID', studyUID);

% Filter by series description
t1_series = dicomquery(conn, 'Series', ...
    'StudyInstanceUID', studyUID, ...
    'SeriesDescription', '*T1*');
```

### Query Results Table

```matlab
results = dicomquery(conn, 'Study', 'PatientID', 'PAT001');

% Results is a table with columns:
% - PatientID
% - PatientName
% - StudyInstanceUID
% - StudyDate
% - StudyTime
% - StudyDescription
% - ModalitiesInStudy
% - NumberOfStudyRelatedSeries
% - etc.

% Access specific fields
for i = 1:height(results)
    fprintf('Study %d: %s (%s)\n', i, ...
        results.StudyDescription{i}, ...
        results.StudyDate{i});
end
```

## Retrieving Images

### Retrieve Entire Study

```matlab
% Query for study
studies = dicomquery(conn, 'Study', 'PatientID', 'PAT001');

% Retrieve to local folder
outputFolder = 'retrieved_images';
dicomget(conn, studies(1,:), outputFolder);

% Load retrieved images
V = medicalVolume(outputFolder);
```

### Retrieve Specific Series

```matlab
% Query for series
series = dicomquery(conn, 'Series', ...
    'StudyInstanceUID', studyUID, ...
    'Modality', 'CT');

% Retrieve specific series
dicomget(conn, series(1,:), outputFolder);
```

### Retrieve with Progress

```matlab
% Create output folder
outputFolder = fullfile(pwd, 'dicom_download');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Retrieve with status display
fprintf('Retrieving %d series...\n', height(series));
for i = 1:height(series)
    fprintf('  Series %d/%d: %s\n', i, height(series), ...
        series.SeriesDescription{i});
    dicomget(conn, series(i,:), outputFolder);
end
fprintf('Download complete.\n');
```

## Storing Images to PACS

### Store Single File

```matlab
conn = dicomConnection('pacs.hospital.org', 4006);

% Store single DICOM file
dicomstore(conn, 'processed_image.dcm');
```

### Store Folder

```matlab
% Store all DICOM files in folder
dicomstore(conn, 'processed_folder/');
```

### Store After Processing

```matlab
% Load original from PACS
studies = dicomquery(conn, 'Study', 'PatientID', 'PAT001');
dicomget(conn, studies(1,:), 'temp_folder');

% Load and process
V = medicalVolume('temp_folder');
V.Voxels = imgaussfilt3(double(V.Voxels), 1.5);  % Process

% Write as DICOM (need to create proper DICOM files)
% See file-io-dicom.md for DICOM writing details
outputFolder = 'processed_dicom';
writeDICOMSeries(V, outputFolder);

% Store back to PACS
dicomstore(conn, outputFolder);
```

## Clinical Workflow Patterns

### Morning Worklist

```matlab
function pullWorkList(conn, date)
    % Find all studies from today
    if nargin < 2
        date = datestr(now, 'yyyymmdd');
    end

    studies = dicomquery(conn, 'Study', 'StudyDate', date);

    fprintf('Studies for %s:\n', date);
    fprintf('%-15s %-30s %-10s %-20s\n', ...
        'PatientID', 'PatientName', 'Modality', 'Description');
    fprintf('%s\n', repmat('-', 1, 80));

    for i = 1:height(studies)
        fprintf('%-15s %-30s %-10s %-20s\n', ...
            studies.PatientID{i}, ...
            studies.PatientName{i}, ...
            studies.ModalitiesInStudy{i}, ...
            studies.StudyDescription{i});
    end
end
```

### Batch Processing Pipeline

```matlab
function batchProcess(conn, dateRange)
    % Find studies to process
    studies = dicomquery(conn, 'Study', ...
        'StudyDate', dateRange, ...
        'Modality', 'CT');

    fprintf('Found %d studies to process\n', height(studies));

    for i = 1:height(studies)
        fprintf('\n[%d/%d] Processing %s...\n', i, height(studies), ...
            studies.PatientID{i});

        try
            % Create temp folder for this patient
            tempFolder = fullfile(tempdir, studies.PatientID{i});
            mkdir(tempFolder);

            % Download
            fprintf('  Downloading...\n');
            dicomget(conn, studies(i,:), tempFolder);

            % Load
            V = medicalVolume(tempFolder);

            % Process
            fprintf('  Processing...\n');
            results = processVolume(V);

            % Save results
            fprintf('  Saving results...\n');
            saveResults(studies.PatientID{i}, results);

            % Clean up
            rmdir(tempFolder, 's');

        catch ME
            fprintf('  ERROR: %s\n', ME.message);
            continue;
        end
    end

    fprintf('\nBatch processing complete.\n');
end
```

### Research Data Export

```matlab
function exportForResearch(conn, patientList, outputDir)
    % Export anonymized data for research

    for i = 1:length(patientList)
        patientID = patientList{i};
        fprintf('Exporting %s...\n', patientID);

        % Find all studies
        studies = dicomquery(conn, 'Study', 'PatientID', patientID);

        for j = 1:height(studies)
            % Download
            tempFolder = fullfile(tempdir, sprintf('export_%d_%d', i, j));
            mkdir(tempFolder);
            dicomget(conn, studies(j,:), tempFolder);

            % Anonymize
            anonFolder = fullfile(outputDir, sprintf('Subject%03d', i), ...
                sprintf('Study%02d', j));
            mkdir(anonFolder);

            files = dir(fullfile(tempFolder, '**', '*.dcm'));
            for k = 1:length(files)
                inFile = fullfile(files(k).folder, files(k).name);
                outFile = fullfile(anonFolder, sprintf('img%04d.dcm', k));
                dicomanon(inFile, outFile, ...
                    'update', {'PatientID', sprintf('Subject%03d', i)});
            end

            % Clean temp
            rmdir(tempFolder, 's');
        end
    end

    fprintf('Export complete: %s\n', outputDir);
end
```

## Error Handling

### Connection Errors

```matlab
function conn = safeConnect(host, port, maxRetries)
    if nargin < 3
        maxRetries = 3;
    end

    for attempt = 1:maxRetries
        try
            conn = dicomConnection(host, port);
            echo(conn);  % Verify connection
            fprintf('Connected to PACS\n');
            return;
        catch ME
            fprintf('Attempt %d failed: %s\n', attempt, ME.message);
            if attempt < maxRetries
                pause(5);  % Wait before retry
            end
        end
    end

    error('Failed to connect to PACS after %d attempts', maxRetries);
end
```

### Query Errors

```matlab
function results = safeQuery(conn, level, varargin)
    try
        results = dicomquery(conn, level, varargin{:});
        if isempty(results) || height(results) == 0
            warning('Query returned no results');
        end
    catch ME
        if contains(ME.message, 'timeout')
            warning('Query timeout - try narrowing search criteria');
        elseif contains(ME.message, 'connection')
            error('Connection lost during query');
        else
            rethrow(ME);
        end
        results = table();
    end
end
```

### Retrieve Errors

```matlab
function success = safeRetrieve(conn, queryResult, outputFolder)
    success = false;

    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    try
        dicomget(conn, queryResult, outputFolder);

        % Verify files were downloaded
        files = dir(fullfile(outputFolder, '**', '*.dcm'));
        if isempty(files)
            warning('No DICOM files retrieved');
            return;
        end

        fprintf('Retrieved %d files\n', length(files));
        success = true;

    catch ME
        fprintf('Retrieve failed: %s\n', ME.message);

        % Clean up partial download
        if exist(outputFolder, 'dir')
            rmdir(outputFolder, 's');
        end
    end
end
```

## Security Considerations

### Network Security

```matlab
% PACS connections should be on secure networks
% Consider:
% - VPN for remote access
% - Firewall rules limiting DICOM ports
% - TLS/SSL if supported (DICOM TLS)

% Check connection security
conn = dicomConnection('pacs.hospital.org', 4006);
disp(conn);  % Review connection properties
```

### Data Privacy

```matlab
% Always anonymize before exporting for research
dicomanon(inputFile, outputFile, ...
    'remove', {'PatientName', 'PatientBirthDate', 'PatientAddress'}, ...
    'update', {'PatientID', 'ANON001'});

% Remove all private tags
dicomanon(inputFile, outputFile, 'DeletePrivate', true);
```

## Common PACS Systems

| PACS | Typical Port | AE Title Example |
|------|--------------|------------------|
| DCM4CHEE | 11112 | DCM4CHEE |
| Orthanc | 4242 | ORTHANC |
| Horos | 11112 | HOROS |
| ClearCanvas | 104 | CLEARCANVAS |
| Commercial | 104, 4006 | Varies |

## Troubleshooting

### Issue: Connection refused

```matlab
% Check network connectivity
system('ping pacs.hospital.org');

% Verify port is open
% (from terminal: nc -zv pacs.hospital.org 4006)

% Check firewall rules
% DICOM typically uses ports 104, 4006, 11112
```

### Issue: Query returns empty

```matlab
% Check query parameters
% - PatientID might be case-sensitive
% - Dates must be YYYYMMDD format
% - Use wildcards: '*' matches any, '?' matches one char

% Try broader query first
all_today = dicomquery(conn, 'Study', 'StudyDate', datestr(now, 'yyyymmdd'));
```

### Issue: Retrieve timeout

```matlab
% Large studies may timeout
% Try retrieving series by series instead of whole study

series = dicomquery(conn, 'Series', 'StudyInstanceUID', studyUID);
for i = 1:height(series)
    dicomget(conn, series(i,:), outputFolder);
end
```

---

*Source: Medical Imaging Toolbox User's Guide, Chapter 2*
*See also: `file-io-dicom.md` for DICOM file handling*
