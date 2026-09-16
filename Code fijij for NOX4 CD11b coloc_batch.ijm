// Fiji Multi-Folder Automation - IMAGEJ MACRO PRODUCTION VERSION
// =========================================================================
// 1. PATHWAYS & YOUR EXACT VISUAL THRESHOLDS
// =========================================================================
inputParentDir = "Choose the Input Directory containing your images"; 
outputCsvPath  = "Choose the Output Folder"; 

greenManualThreshold = 55;  // Your locked Microglia threshold
redManualThreshold   = 58;  // Your locked NOX4 threshold
// =========================================================================

// Initialize or clear old data sheets fresh
if (File.exists(outputCsvPath)) {
    File.delete(outputCsvPath);
}
File.append("Animal_Folder,NOX4_Percent_Area_Inside_Microglia", outputCsvPath);

print("--- Starting Silent Mask-Area Batch Analysis ---");
setBatchMode(true); // Runs silently in the background at maximum speed
processFolder(inputParentDir);
setBatchMode(false);
print("--- Batch Analysis Complete! ---");

function processFolder(currentDir) {
    list = getFileList(currentDir);
    ch1Path = "";
    ch2Path = "";
    
    // Scan files at this specific folder level
    for (i = 0; i < list.length; i++) {
        if (File.isDirectory(currentDir + list[i])) {
            processFolder(currentDir + list[i]); // Enter nested folder level recursively
        } else {
            fileName = toLowerCase(list[i]);
            if ((endsWith(fileName, ".tif") || endsWith(fileName, ".tiff")) && indexOf(fileName, "overlay") == -1 && indexOf(fileName, "merge") == -1) {
                if (indexOf(fileName, "ch01") != -1 || indexOf(fileName, "ch1") != -1 || indexOf(fileName, "green") != -1) {
                    ch1Path = currentDir + list[i];
                }
                if (indexOf(fileName, "ch02") != -1 || indexOf(fileName, "ch2") != -1 || indexOf(fileName, "red") != -1) {
                    ch2Path = currentDir + list[i];
                }
            }
        }
    }
    
    // If a valid green/red channel pair is identified, run your selection workflow
    if (ch1Path != "" && ch2Path != "") {
        // Extract parent folder name for row labeling
        parts = split(currentDir, "/");
        animalName = parts[parts.length-1];
        print("Processing folder: " + animalName);
        
        open(ch1Path);
        title1 = getTitle();
        open(ch2Path);
        title2 = getTitle();
        
        // Force RGB color files to raw 8-bit intensity maps
        selectWindow(title1);
        run("8-bit");
        selectWindow(title2);
        run("8-bit");
        
        // --- STEP A: SEGMENT, DILATE & CLOSE MICROGLIA (GREEN) ---
        selectWindow(title1);
        setThreshold(greenManualThreshold, 255);
        run("Convert to Mask");
        run("Dilate");
        run("Close-");
        run("Create Selection");
        
        // Check if real microglia cells actually exist in this frame
        type = selectionType();
        percentArea = 0;
        
        if (type != -1) {
            // --- STEP B: RESTORE UNIFIED SELECTION MASK TO NOX4 (RED) & MEASURE ---
            selectWindow(title2);
            run("Restore Selection");
            setThreshold(redManualThreshold, 255);
            run("Convert to Mask");
            
            run("Clear Results");
            run("Set Measurements...", "area_fraction display redirect=None decimal=3");
            run("Measure");
            
            if (nResults > 0) {
                percentArea = getResult("%Area", nResults - 1);
            }
        }
        
        // Log clean metrics to your final spreadsheet file
        File.append(animalName + "," + percentArea, outputCsvPath);
        
        // Hard wipe active windows to keep computer RAM clean
        run("Close All");
    }
}
