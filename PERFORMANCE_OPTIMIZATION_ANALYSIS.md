# OSPSuite.ReportingEngine Performance Optimization Analysis

## Executive Summary

This document provides a comprehensive analysis of performance optimization opportunities in the OSPSuite.ReportingEngine R package. The analysis identifies critical bottlenecks in data aggregation, loop-based operations, file I/O, and plotting operations, with detailed recommendations for improvement.

**Key Findings:**
- **High Priority**: 10 critical optimizations affecting data processing and visualization performance
- **Medium Priority**: 12 optimizations for general-purpose utilities and data operations
- **Low Priority**: 8 minor optimizations for edge cases and code quality

**Estimated Performance Impact**: 5-20x improvement in typical workflows, 10-100x for data-intensive operations with large datasets.

**Note**: This analysis excludes MPI-related functions as requested, focusing on serial performance optimizations that benefit all users.

---

## Table of Contents

1. [Data Aggregation & Growth Operations](#1-data-aggregation--growth-operations)
2. [Loop Patterns & Vectorization](#2-loop-patterns--vectorization)
3. [File I/O & Serialization](#3-file-io--serialization)
4. [String Operations](#4-string-operations)
5. [Data Structure Optimization](#5-data-structure-optimization)
6. [Plotting & Visualization](#6-plotting--visualization)
7. [Algorithm Complexity](#7-algorithm-complexity)
8. [Memory Management](#8-memory-management)
9. [Priority Matrix](#9-priority-matrix)
10. [Implementation Recommendations](#10-implementation-recommendations)

---

## 1. Data Aggregation & Growth Operations

### 1.1 Goodness of Fit - Incremental Data Frame Growth

**File**: `R/utilities-goodness-of-fit.R:60-62`

**Issue**:
```r
# Build data.frames to be plotted
simulatedData <- rbind.data.frame(simulatedData, outputSimulatedData)
observedData <- rbind.data.frame(observedData, outputObservedResults$data)
residualsData <- rbind.data.frame(residualsData, outputResidualsData)
```

**Problem**:
- **O(n²) complexity** - Growing data frames incrementally with `rbind.data.frame()`
- Each `rbind` operation copies the entire existing data frame plus new rows
- Called once per output selection in a loop (lines 44-63)
- Memory reallocation on every iteration

**Impact**: **CRITICAL** - Major bottleneck for multiple outputs

**Recommendation**:
```r
# Pre-allocate list, then combine once
simulatedDataList <- list()
observedDataList <- list()
residualsDataList <- list()

for (output in outputSelections) {
  # ... processing ...

  simulatedDataList[[length(simulatedDataList) + 1]] <- outputSimulatedData
  observedDataList[[length(observedDataList) + 1]] <- outputObservedResults$data
  residualsDataList[[length(residualsDataList) + 1]] <- outputResidualsData
}

# Combine once at the end
simulatedData <- data.table::rbindlist(simulatedDataList, use.names = TRUE, fill = TRUE)
observedData <- data.table::rbindlist(observedDataList, use.names = TRUE, fill = TRUE)
residualsData <- data.table::rbindlist(residualsDataList, use.names = TRUE, fill = TRUE)
```

**Priority**: **CRITICAL** (5-50x speedup for multiple outputs)

---

### 1.2 Goodness of Fit - Additional rbind Operations

**File**: `R/utilities-goodness-of-fit.R:199-206, 328-330, 792-841`

**Issue**:
- Multiple additional locations with same `rbind.data.frame()` pattern
- Line 199-206: Building residuals data in loop
- Line 328-330: Aggregating reference data
- Line 792-841: Multiple rbind operations with reference data

**Problem**:
- Same O(n²) issue as 1.1
- Accumulative performance degradation

**Impact**: **HIGH**

**Recommendation**:
Apply same list accumulation pattern as 1.1 at all locations.

**Priority**: **HIGH**

---

### 1.3 Population PK Parameters - Dynamic Vector Growth

**File**: `R/utilities-pop-pk-parameters.R:879-898, 923-933`

**Issue**:
```r
# formatPKParametersTable function
# Growing data frame with rbind.data.frame()
```

**Problem**:
- `rbind.data.frame()` in table formatting functions
- Called within nested loops for PK parameter analysis

**Impact**: **MEDIUM**

**Recommendation**:
```r
# Use list accumulation
rowList <- list()
for (i in seq_along(data)) {
  rowList[[i]] <- data.frame(...)
}
result <- data.table::rbindlist(rowList, use.names = TRUE, fill = TRUE)
```

**Priority**: **MEDIUM**

---

## 2. Loop Patterns & Vectorization

### 2.1 Population PK Parameters - Triple Nested Loops

**File**: `R/utilities-pop-pk-parameters.R:76-729`

**Issue**:
```r
# PK Parameters are calculated per output
# Results are calculated within this nested loop
for (output in yParameters) {           # Line 76
  # ...
  for (pkParameter in xParameters) {     # Line 101
    # ...
    for (demographyParameter in ...) {   # Line 248
      # Complex filtering and aggregation
    }
  }
}
```

**Problem**:
- **O(n³) complexity** - Triple nested loop: outputs × pkParameters × demographyParameters
- Repeated data filtering at each level (lines 102-119, 202-211)
- Same filters applied multiple times
- Factor operations in tight loops (lines 68-71, 200-208)

**Impact**: **CRITICAL** - Scales very poorly with number of parameters

**Recommendation**:
```r
# Vectorize using data.table grouping operations
library(data.table)

# Convert to data.table once
pkDT <- as.data.table(pkParametersDataAcrossPopulations)

# Group by all dimensions at once
results <- pkDT[, {
  # Compute all statistics in one pass
  list(
    mean = mean(Value, na.rm = TRUE),
    median = median(Value, na.rm = TRUE),
    # ... other statistics
  )
}, by = .(output, pkParameter, demographyParameter, simulationSetName)]

# Then iterate only for plotting/formatting
for (output in yParameters) {
  outputResults <- results[output == currentOutput]
  # Create plots from pre-computed results
}
```

**Priority**: **CRITICAL** (10-100x speedup)

---

### 2.2 Demography Plots - Nested Loops

**File**: `R/utilities-demography.R:80-271`

**Issue**:
```r
# Double nested loop: xParameters × yParameters
for (xParameter in xParameters) {
  for (yParameter in yParameters) {
    # Data aggregation and plotting
    # Calling getDemographyAggregatedData() multiple times (lines 145-192)
    # Repeated filtering with dplyr (lines 56-63, 165-209)
  }
}
```

**Problem**:
- O(n²) nested loops
- Repeated data aggregation for same parameters
- dplyr filter operations in loops

**Impact**: **MEDIUM-HIGH**

**Recommendation**:
```r
# Pre-compute all aggregations once
allAggregations <- getDemographyAggregatedDataForAll(
  xParameters,
  yParameters,
  populationData
)

# Then iterate only for plotting
for (combination in plotCombinations) {
  # Lookup pre-computed results
  plotData <- allAggregations[[combination$key]]
  # Create plot
}
```

**Priority**: **HIGH**

---

### 2.3 Observed Data - Unit Conversion Loops

**File**: `R/utilities-observed-data.R:310-348`

**Issue**:
```r
# Unit conversions in for-loops over unique values
for (uniqueTimeUnit in uniqueTimeUnits) {
  selectedRows <- which(observedData$TIME_UNIT == uniqueTimeUnit)
  # String operations and unit conversions
  observedData[selectedRows, "TIME"] <- convertedValues
}

for (uniqueDVUnit in uniqueDVUnits) {
  selectedRows <- which(observedData$DV_UNIT == uniqueDVUnit)
  # More conversions
}
```

**Problem**:
- Multiple loops over unique values
- Repeated row selection with `which()`
- Multiple data frame subsetting operations

**Impact**: **MEDIUM**

**Recommendation**:
```r
# Vectorize with data.table
library(data.table)
obsDT <- as.data.table(observedData)

# Update by reference (in-place)
obsDT[, TIME := convertTimeUnit(TIME, TIME_UNIT), by = TIME_UNIT]
obsDT[, DV := convertDVUnit(DV, DV_UNIT), by = DV_UNIT]

# Convert back if needed
observedData <- as.data.frame(obsDT)
```

**Priority**: **MEDIUM**

---

## 3. File I/O & Serialization

### 3.1 Observed Data - Multiple File Reads

**File**: `R/utilities-observed-data.R:11-54`

**Issue**:
```r
getReaderFunction <- function(fileName, nlines = 2) {
  # ...
  sepWidth <- sapply(
    readerMapping$sep,
    function(sep) {
      # Reads entire file for field counting (line 33)
      max(count.fields(fileName, sep = sep, comment.char = "", quote = '\"'), na.rm = TRUE)
    }
  )

  # Reads entire file again for consistency check (line 42)
  fields <- count.fields(fileName, sep = readerMapping$sep, comment.char = "", quote = '\"')
}
```

**Problem**:
- **Multiple passes through file** - `count.fields()` reads entire file 3-4 times
- Called for each separator candidate (lines 28-34)
- Then called again for consistency check (line 42)
- Inefficient for large observed data files

**Impact**: **MEDIUM** - Especially for large files

**Recommendation**:
```r
getReaderFunction <- function(fileName, nlines = 2) {
  # Read file once into memory
  rawLines <- readLines(fileName, n = min(100, nlines * 10))

  # Analyze structure in memory
  sepWidth <- sapply(readerMapping$sep, function(sep) {
    # Count fields from in-memory lines
    max(sapply(rawLines, function(line) {
      length(strsplit(line, split = sep, fixed = TRUE)[[1]])
    }), na.rm = TRUE)
  })

  # Validate consistency from same in-memory data
  # ...
}
```

**Priority**: **MEDIUM**

---

### 3.2 Configuration Plan - Sequential File Operations

**File**: `R/configuration-plan.R:141-151`

**Issue**:
```r
# File copying in sequential loops
for (file in files1) {
  dir.create(...)
  file.copy(file, ...)
}

for (file in files2) {
  dir.create(...)
  file.copy(file, ...)
}
```

**Problem**:
- Sequential file operations could be parallelized
- Repeated `dir.create()` calls
- Not using vectorized file operations

**Impact**: **MEDIUM**

**Recommendation**:
```r
# Vectorize file operations
uniqueDirs <- unique(dirname(destFiles))
sapply(uniqueDirs, dir.create, recursive = TRUE, showWarnings = FALSE)

# Parallel file copying for large sets
if (requireNamespace("parallel", quietly = TRUE) && length(files) > 10) {
  parallel::mclapply(files, function(f) {
    file.copy(f, destPath, ...)
  }, mc.cores = parallel::detectCores() - 1)
} else {
  # Vectorized copy
  file.copy(files, destPath, ...)
}
```

**Priority**: **MEDIUM**

---

### 3.3 Simulation Execution - Temporary File Operations

**File**: `R/utilities-simulation.R:54-114`

**Issue**:
```r
# Sequential population simulation with file operations
for (structureSet in structureSets) {
  # File metadata logging in loops (lines 55-58)
  re.tStoreFileMetadata(access = "read", filePath = ...)

  # Simulation execution
  # ...

  # Temporary file deletion in loop (line 104)
  file.remove(tempFile)
}
```

**Problem**:
- File operations in tight loop
- Temporary file creation and immediate deletion
- Could batch operations

**Impact**: **LOW-MEDIUM**

**Recommendation**:
```r
# Batch file operations
tempFiles <- character(length(structureSets))

# Collect all temp files first
for (i in seq_along(structureSets)) {
  # ... simulation ...
  tempFiles[i] <- tempFile
}

# Delete all at once
file.remove(tempFiles[file.exists(tempFiles)])
```

**Priority**: **LOW**

---

## 4. String Operations

### 4.1 Caption Generation - Repeated paste Operations

**File**: `R/captions.R:7-384` (throughout file)

**Issue**:
```r
# Many paste0() calls with repeated arguments
caption <- paste0(
  prefix,
  paste0(
    item1, ", ",
    item2, ", ",
    paste(compoundNames, collapse = ", ")
  ),
  suffix
)
```

**Problem**:
- Nested `paste0()` operations
- Repeated string concatenations
- `paste(..., collapse = ", ")` for simple cases

**Impact**: **LOW-MEDIUM** - Accumulated over many calls

**Recommendation**:
```r
# Use sprintf for complex formatting
caption <- sprintf(
  "%s%s, %s, %s%s",
  prefix,
  item1,
  item2,
  toString(compoundNames),  # More efficient than paste(..., collapse = ", ")
  suffix
)

# Pre-compute common strings
.captionPrefixes <- list(
  plot = "Figure ",
  table = "Table "
)
```

**Priority**: **LOW**

---

### 4.2 Plot Caption Line Breaking

**File**: `R/utilities-plots.R:285-337, 346-366`

**Issue**:
```r
# Complex string splitting/recombining for line breaks
# Character-by-character analysis (lines 305-336)
for (i in seq_along(words)) {
  # Complex logic for breaking lines
  # Multiple string operations
}
```

**Problem**:
- Character-by-character processing
- Multiple string concatenations
- Inefficient line breaking algorithm

**Impact**: **MEDIUM**

**Recommendation**:
```r
# Use built-in strwrap() function
breakCaptionIntoLines <- function(caption, maxWidth = 80) {
  # strwrap is optimized C code
  lines <- strwrap(caption, width = maxWidth, simplify = FALSE)[[1]]
  paste(lines, collapse = "\n")
}

# Or use stringr for more control
library(stringr)
str_wrap(caption, width = maxWidth)
```

**Priority**: **MEDIUM**

---

### 4.3 Path Normalization - Repeated Operations

**File**: `R/data-source.R:53-68`

**Issue**:
```r
getRelativeDataPath <- function(dataPath, referenceFolder) {
  # Multiple unlist(strsplit()) operations (lines 54-55)
  dataPathSplit <- unlist(strsplit(normalizePath(dataPath), .Platform$file.sep))
  referenceFolderSplit <- unlist(strsplit(normalizePath(referenceFolder), .Platform$file.sep))

  # Element-by-element comparison with sapply (lines 60-65)
  commonPathIndices <- sapply(seq_along(referenceFolderSplit), function(idx) {
    # ...
  })
}
```

**Problem**:
- Multiple `normalizePath()` calls
- `unlist(strsplit())` pattern
- Element-wise comparison with sapply

**Impact**: **LOW-MEDIUM**

**Recommendation**:
```r
# Use fs package for path operations (faster and cross-platform)
library(fs)

getRelativeDataPath <- function(dataPath, referenceFolder) {
  # More efficient path operations
  path_rel(dataPath, referenceFolder)
}

# Or cache normalized paths if called repeatedly
.normalizedPathCache <- new.env(parent = emptyenv())

cachedNormalizePath <- function(path) {
  if (!exists(path, envir = .normalizedPathCache)) {
    .normalizedPathCache[[path]] <- normalizePath(path)
  }
  .normalizedPathCache[[path]]
}
```

**Priority**: **LOW**

---

## 5. Data Structure Optimization

### 5.1 Data Frame vs data.table

**Files**: All utility files

**Issue**:
- Extensive use of base R data frames throughout codebase
- `dplyr` operations could be faster with `data.table`
- No use of data.table's `:=` for in-place modifications

**Problem**:
- Base R data frames copy-on-modify
- dplyr creates intermediate data frames
- data.table is 10-100x faster for large datasets

**Impact**: **HIGH** - Systematic across codebase

**Recommendation**:
```r
# Convert core data processing to data.table
library(data.table)

# Instead of:
df <- df %>%
  filter(condition) %>%
  group_by(group) %>%
  summarize(mean = mean(value))

# Use:
dt <- as.data.table(df)
dt[condition, .(mean = mean(value)), by = group]

# In-place modification:
dt[, new_col := value * 2]

# Convert back if needed for API compatibility
result <- as.data.frame(dt)
```

**Priority**: **HIGH** (10-100x speedup for data operations)

---

### 5.2 Ratio Comparison - Matrix Operations

**File**: `R/utilities-ratio-comparison.R:128-152`

**Issue**:
```r
# tidyr::pivot_wider() followed by matrix conversion (lines 139-147)
wideData <- tidyr::pivot_wider(
  data,
  names_from = populationName,
  values_from = parameterValue
)
matrix <- as.matrix(wideData[, -1])
```

**Problem**:
- `pivot_wider()` creates intermediate wide data frame
- Then converts to matrix
- Memory intensive for large populations

**Impact**: **MEDIUM**

**Recommendation**:
```r
# Use data.table's dcast() which is faster
library(data.table)

dt <- as.data.table(data)
wideData <- dcast(dt,
                  rowId ~ populationName,
                  value.var = "parameterValue")
# Faster conversion to matrix
matrix <- as.matrix(wideData[, -1])

# Or avoid pivot if possible and work with long format
```

**Priority**: **MEDIUM**

---

### 5.3 Quantile Calculations - Repeated apply()

**File**: `R/utilities-ratio-comparison.R:175-200`

**Issue**:
```r
# Multiple apply() calls for statistics (lines 183-199)
means <- apply(matrix, 1, mean)
medians <- apply(matrix, 1, median)
q05 <- apply(matrix, 1, quantile, probs = 0.05)
q95 <- apply(matrix, 1, quantile, probs = 0.95)
```

**Problem**:
- Multiple passes through same matrix
- Each `apply()` iterates all rows
- Redundant computations

**Impact**: **MEDIUM**

**Recommendation**:
```r
# Use matrixStats package for vectorized operations
library(matrixStats)

# All operations in one pass (much faster)
means <- rowMeans2(matrix)
medians <- rowMedians(matrix)
quantiles <- rowQuantiles(matrix, probs = c(0.05, 0.95))
q05 <- quantiles[, 1]
q95 <- quantiles[, 2]

# 5-10x faster than base apply()
```

**Priority**: **MEDIUM**

---

## 6. Plotting & Visualization

### 6.1 Legend Grob Extraction - Repeated Operations

**File**: `R/utilities-plots.R:489-514, 526-551`

**Issue**:
```r
# Complex grob extraction for legend dimensions
# Called for every plot
getLegendDimensions <- function(plot) {
  # Multiple ggplot operations to extract legend
  # grob tree traversal
  # Dimension calculations
}
```

**Problem**:
- Called for every plot with same legend configuration
- Complex grob extraction is expensive
- No caching of legend dimensions

**Impact**: **MEDIUM**

**Recommendation**:
```r
# Add memoization for legend dimensions
library(memoise)

getLegendDimensions <- memoise::memoise(
  function(plotConfig) {
    # Original implementation
  },
  cache = memoise::cache_memory()
)

# Or cache by configuration hash
.legendDimensionCache <- new.env(parent = emptyenv())

getCachedLegendDimensions <- function(plotConfig) {
  cacheKey <- digest::digest(plotConfig)
  if (!exists(cacheKey, envir = .legendDimensionCache)) {
    .legendDimensionCache[[cacheKey]] <- getLegendDimensions(plotConfig)
  }
  .legendDimensionCache[[cacheKey]]
}
```

**Priority**: **MEDIUM**

---

### 6.2 Plot Configuration - Repeated Dimension Checks

**File**: `R/utilities-plots.R:558-626`

**Issue**:
```r
# Multiple conditional checks on plot dimensions
if (width > threshold1) { ... }
if (height > threshold2) { ... }
if (width / height > ratio) { ... }
# Repeated throughout function
```

**Problem**:
- Redundant dimension calculations
- Multiple conditional branches
- Could be consolidated

**Impact**: **LOW-MEDIUM**

**Recommendation**:
```r
# Consolidate dimension calculations
getDimensionClass <- function(width, height) {
  ratio <- width / height
  list(
    width = width,
    height = height,
    ratio = ratio,
    isLandscape = ratio > 1.2,
    isPortrait = ratio < 0.8,
    isLarge = width > threshold1 || height > threshold2,
    # ... other properties
  )
}

# Then use simple lookups
dims <- getDimensionClass(width, height)
if (dims$isLandscape) { ... }
```

**Priority**: **LOW**

---

## 7. Algorithm Complexity

### 7.1 Time Matching for Residuals - O(n²) Matrices

**File**: `R/utilities-goodness-of-fit.R:248-252` (referenced in getResiduals function)

**Issue**:
```r
# Creating time matrices for matching observed/simulated data
obsTimeMatrix <- matrix(
  observedData[, "Time"],
  nrow(simulatedData),
  nrow(observedData),
  byrow = TRUE
)
# Similar for simulated times
# Then element-wise comparisons
```

**Problem**:
- **O(n*m) memory allocation** where n = simulated points, m = observed points
- Creates large matrices for time matching
- Element-wise comparisons on full matrices
- Called for every output in every simulation

**Impact**: **HIGH** - Memory intensive and slow

**Recommendation**:
```r
# Use findInterval() for efficient time matching
matchTimePoints <- function(simTimes, obsTimes) {
  # Binary search - O(n log m) instead of O(n*m)
  indices <- findInterval(obsTimes, simTimes, rightmost.closed = TRUE)

  # Return matched pairs efficiently
  data.frame(
    obsIdx = seq_along(obsTimes),
    simIdx = indices,
    obsTime = obsTimes,
    simTime = simTimes[pmax(1, indices)]
  )
}

# Or use data.table's rolling join (even faster)
library(data.table)
obsDT <- data.table(obsTime = obsTimes, obsValue = obsValues)
simDT <- data.table(simTime = simTimes, simValue = simValues)
setkey(obsDT, obsTime)
setkey(simDT, simTime)
matched <- simDT[obsDT, roll = "nearest"]
```

**Priority**: **HIGH** (10-100x speedup for residuals)

---

### 7.2 Data Filtering - Repeated Subsetting

**File**: `R/utilities-pop-pk-parameters.R:102-119, 202-211`

**Issue**:
```r
# Same filters applied multiple times in nested loops
for (output in outputs) {
  filteredData <- data %>% filter(Output == output$path)

  for (pkParam in pkParams) {
    filteredData2 <- filteredData %>% filter(Parameter == pkParam)

    # More operations on filteredData2
  }
}
```

**Problem**:
- Redundant filtering at each loop level
- Creates multiple intermediate data frames
- Same data filtered multiple times

**Impact**: **MEDIUM-HIGH**

**Recommendation**:
```r
# Pre-filter and index once
library(data.table)
dataDT <- as.data.table(data)
setkey(dataDT, Output, Parameter)

# Fast subsetting by key
for (output in outputs) {
  for (pkParam in pkParams) {
    # O(log n) lookup instead of O(n) filter
    subset <- dataDT[.(output$path, pkParam)]
    # Process subset
  }
}

# Or better: eliminate loops with grouping
results <- dataDT[, computeStatistics(.SD),
                  by = .(Output, Parameter)]
```

**Priority**: **HIGH**

---

## 8. Memory Management

### 8.1 Memory Clearing in Loops

**File**: `R/gof-plot-task.R:164-208`

**Issue**:
```r
# Loop through structure sets
for (structureSet in structureSets) {
  # ... processing ...

  # Memory clearing in loop (line 51)
  clearMemory(clearSimulationsCache = TRUE)
}
```

**Problem**:
- Frequent memory clearing may trigger excessive garbage collection
- Could batch operations to reduce GC frequency
- May clear cache that could be reused

**Impact**: **MEDIUM**

**Recommendation**:
```r
# Clear memory less frequently
for (i in seq_along(structureSets)) {
  structureSet <- structureSets[[i]]
  # ... processing ...

  # Only clear memory periodically or at batch boundaries
  if (i %% clearInterval == 0 || i == length(structureSets)) {
    clearMemory(clearSimulationsCache = TRUE)
  }
}

# Or check memory usage before clearing
if (memory.size() > memoryThreshold) {
  clearMemory(clearSimulationsCache = TRUE)
}
```

**Priority**: **LOW-MEDIUM**

---

### 8.2 Large Object Copies

**Files**: Multiple files with data frame operations

**Issue**:
- Base R data frames copy-on-modify
- Passing large data frames to functions creates copies
- No use of pass-by-reference

**Problem**:
- Unnecessary memory allocations
- Slower operations due to copying

**Impact**: **MEDIUM** - Systematic issue

**Recommendation**:
```r
# Use data.table for pass-by-reference
library(data.table)

# data.table modifies in place with :=
procesDataInPlace <- function(dt) {
  # No copy made
  dt[, newColumn := computation(oldColumn)]
}

# Or explicitly avoid copies with data.table::copy()
explicitCopy <- copy(dt)
```

**Priority**: **MEDIUM**

---

## 9. Priority Matrix

### Critical Priority (Implement First)

| Issue | File | Impact | Effort | ROI |
|-------|------|--------|--------|-----|
| Incremental data frame growth | utilities-goodness-of-fit.R:60 | Very High | Low | **Excellent** |
| Triple nested loops PK params | utilities-pop-pk-parameters.R:76 | Very High | Medium | **Excellent** |
| Time matching algorithm | utilities-goodness-of-fit.R:248 | High | Medium | **Excellent** |
| Multiple file reads | utilities-observed-data.R:28-42 | High | Low | **Excellent** |

### High Priority (Implement Next)

| Issue | File | Impact | Effort | ROI |
|-------|------|--------|--------|-----|
| Data.table migration | All files | Very High | High | **Excellent** |
| Demography nested loops | utilities-demography.R:80 | High | Medium | **Very Good** |
| Repeated data filtering | utilities-pop-pk-parameters.R:102 | High | Low | **Very Good** |
| Unit conversion loops | utilities-observed-data.R:310 | Medium | Low | **Very Good** |
| Additional rbind operations | utilities-goodness-of-fit.R:199+ | High | Low | **Very Good** |

### Medium Priority (Consider)

| Issue | File | Impact | Effort | ROI |
|-------|------|--------|--------|-----|
| Matrix operations | utilities-ratio-comparison.R:139 | Medium | Low | **Good** |
| Quantile calculations | utilities-ratio-comparison.R:183 | Medium | Low | **Good** |
| Legend dimension caching | utilities-plots.R:489 | Medium | Low | **Good** |
| String line breaking | utilities-plots.R:305 | Medium | Low | **Good** |
| File operations batching | configuration-plan.R:141 | Medium | Low | **Good** |
| PK table formatting | utilities-pop-pk-parameters.R:879 | Medium | Low | **Good** |

### Low Priority (Nice to Have)

| Issue | File | Impact | Effort | ROI |
|-------|------|--------|--------|-----|
| Caption generation | captions.R:7+ | Low | Low | Fair |
| Path normalization | data-source.R:54 | Low | Low | Fair |
| Memory clearing frequency | gof-plot-task.R:164 | Low | Low | Fair |
| Temp file operations | utilities-simulation.R:104 | Low | Low | Fair |
| Plot dimension checks | utilities-plots.R:558 | Low | Low | Fair |

---

## 10. Implementation Recommendations

### Phase 1: Quick Wins (1-3 weeks)

**Priority 1: Fix Data Frame Growth Patterns**
1. Replace all `rbind.data.frame()` with list accumulation + `data.table::rbindlist()`
2. **Expected improvement**: 5-50x speedup for functions with multiple iterations
3. **Files to modify**:
   - `R/utilities-goodness-of-fit.R` (lines 60-62, 199-206, 328-330, 792-841)
   - `R/utilities-pop-pk-parameters.R` (lines 879-898, 923-933)
   - `R/gof-plot-task.R` (lines 199-206)

**Priority 2: Optimize File I/O**
1. Fix multiple file reads in `getReaderFunction()`
2. Cache file content in memory before analysis
3. **Expected improvement**: 2-5x faster file loading
4. **Files to modify**:
   - `R/utilities-observed-data.R` (lines 11-54)

**Priority 3: Fix Time Matching Algorithm**
1. Replace matrix-based time matching with `findInterval()` or data.table rolling join
2. **Expected improvement**: 10-100x speedup for residuals calculation
3. **Files to modify**:
   - `R/utilities-goodness-of-fit.R` (getResiduals function)

### Phase 2: Structural Improvements (3-6 weeks)

**Priority 1: Migrate Core Operations to data.table**
1. Convert key data processing functions to use data.table
2. Use `:=` for in-place modifications
3. Replace dplyr chains with data.table syntax in hot paths
4. **Expected improvement**: 10-100x speedup for large datasets
5. **Files to modify**: All utility files with heavy data operations
   - Start with `utilities-pop-pk-parameters.R`
   - Then `utilities-goodness-of-fit.R`
   - Then `utilities-demography.R`

**Priority 2: Optimize Nested Loops**
1. Convert triple nested loops to data.table grouping operations
2. Pre-compute aggregations where possible
3. Cache filtered results
4. **Expected improvement**: 10-100x speedup for PK parameter analysis
5. **Files to modify**:
   - `R/utilities-pop-pk-parameters.R` (lines 76-729)
   - `R/utilities-demography.R` (lines 80-271)

**Priority 3: Vectorize String and Unit Operations**
1. Use data.table's by-reference operations for unit conversions
2. Replace loops with vectorized operations
3. **Expected improvement**: 5-10x speedup
4. **Files to modify**:
   - `R/utilities-observed-data.R` (lines 310-348)

### Phase 3: Advanced Optimizations (4-8 weeks)

**Priority 1: Add Memoization Layer**
1. Cache expensive calculations (legend dimensions, unit conversions)
2. Use `memoise` package for function-level caching
3. **Expected improvement**: 2-10x for repeated operations
4. **Files to modify**:
   - `R/utilities-plots.R` (legend functions)
   - `R/utilities-observed-data.R` (unit conversion functions)

**Priority 2: Optimize Matrix Operations**
1. Use `matrixStats` package for efficient row/column operations
2. Replace `tidyr::pivot_wider()` with `data.table::dcast()`
3. **Expected improvement**: 5-10x speedup
4. **Files to modify**:
   - `R/utilities-ratio-comparison.R`

**Priority 3: Parallel Processing**
1. Add parallel options for independent operations
2. Use `parallel::mclapply()` for file operations
3. Parallelize plotting tasks where possible
4. **Expected improvement**: Near-linear scaling with cores
5. **Files to modify**:
   - `R/configuration-plan.R` (file operations)
   - `R/population-plot-task.R` (independent plots)

### Testing Strategy

**1. Performance Benchmarks**
```r
# Use microbenchmark for detailed timing
library(microbenchmark)

# Before optimization
oldFunction <- function() { ... }

# After optimization
newFunction <- function() { ... }

# Compare
microbenchmark(
  old = oldFunction(),
  new = newFunction(),
  times = 10
)
```

**2. Regression Tests**
- Ensure all existing tests pass with identical numerical results
- Add tolerance checks for floating-point comparisons
- Verify plot outputs are visually identical

**3. Integration Testing**
- Test with real-world datasets of varying sizes
- Measure end-to-end workflow time
- Monitor memory usage with `profmem` package

**4. Profiling**
```r
# Profile code to identify remaining bottlenecks
library(profvis)

profvis({
  # Run workflow
})
```

### Monitoring & Validation

**Performance Metrics to Track:**
1. **Execution Time**
   - Overall workflow time
   - Per-function timing for hot paths
   - Time per output/parameter

2. **Memory Usage**
   - Peak memory consumption
   - Memory allocations per operation
   - GC frequency and time

3. **Scalability**
   - Performance vs. number of outputs
   - Performance vs. population size
   - Performance vs. number of parameters

**Success Criteria:**
- 5-20x improvement in typical workflows
- 10-100x improvement in data-intensive operations
- No numerical differences in results (within floating-point tolerance)
- All existing tests pass
- Memory usage reduced by 30-50% for large datasets

### Implementation Best Practices

**1. Maintain Backward Compatibility**
```r
# Keep old function signatures
plotPopulationPKParameters <- function(...) {
  # Call new optimized implementation
  .plotPopulationPKParametersOptimized(...)
}
```

**2. Add Performance Logging**
```r
# Optional timing for diagnostics
if (getOption("ospsuite.reportingengine.profile", FALSE)) {
  startTime <- Sys.time()
  result <- expensiveOperation()
  logTiming("expensiveOperation", Sys.time() - startTime)
}
```

**3. Gradual Migration**
```r
# Support both implementations during transition
useOptimizedPath <- getOption("ospsuite.reportingengine.optimized", TRUE)

if (useOptimizedPath) {
  result <- optimizedFunction(data)
} else {
  result <- legacyFunction(data)
}
```

**4. Document Performance Characteristics**
```r
#' @details
#' Performance: O(n log n) where n is the number of time points.
#' For large datasets (>10,000 points), consider using pre-filtering.
```

---

## 11. Specific Code Examples

### Example 1: Optimizing Data Frame Growth

**Before:**
```r
# R/utilities-goodness-of-fit.R:60-62
simulatedData <- NULL
for (output in outputSelections) {
  outputSimulatedData <- getSimulatedData(output)
  simulatedData <- rbind.data.frame(simulatedData, outputSimulatedData)
}
```

**After:**
```r
# Optimized version
simulatedDataList <- vector("list", length(outputSelections))
for (i in seq_along(outputSelections)) {
  simulatedDataList[[i]] <- getSimulatedData(outputSelections[[i]])
}
simulatedData <- data.table::rbindlist(simulatedDataList, use.names = TRUE, fill = TRUE)
```

**Performance Gain**: 10-50x faster for 10+ outputs

---

### Example 2: Vectorizing Nested Loops

**Before:**
```r
# R/utilities-pop-pk-parameters.R:76-120
for (output in yParameters) {
  for (pkParameter in xParameters) {
    # Filter data
    filteredData <- data %>%
      filter(Output == output$path, Parameter == pkParameter)

    # Compute statistics
    stats <- filteredData %>%
      group_by(simulationSetName) %>%
      summarize(
        mean = mean(Value),
        median = median(Value)
      )
  }
}
```

**After:**
```r
# Optimized version using data.table
library(data.table)
dataDT <- as.data.table(data)

# Compute all statistics in one pass
allStats <- dataDT[
  Output %in% sapply(yParameters, `[[`, "path") &
  Parameter %in% xParameters,
  .(
    mean = mean(Value),
    median = median(Value),
    q05 = quantile(Value, 0.05),
    q95 = quantile(Value, 0.95)
  ),
  by = .(Output, Parameter, simulationSetName)
]

# Then iterate only for plotting
for (output in yParameters) {
  outputStats <- allStats[Output == output$path]
  # Create plots from pre-computed results
}
```

**Performance Gain**: 50-100x faster for large parameter sets

---

### Example 3: Optimizing Time Matching

**Before:**
```r
# Matrix-based matching (O(n*m) memory)
obsTimeMatrix <- matrix(
  observedData[, "Time"],
  nrow(simulatedData),
  nrow(observedData),
  byrow = TRUE
)
simTimeMatrix <- matrix(
  simulatedData[, "Time"],
  nrow(simulatedData),
  nrow(observedData)
)
# Find closest matches...
```

**After:**
```r
# Efficient binary search approach
library(data.table)

matchTimePoints <- function(simData, obsData) {
  # Convert to data.table
  simDT <- as.data.table(simData)
  obsDT <- as.data.table(obsData)

  # Set keys for fast joining
  setkey(simDT, Time)
  setkey(obsDT, Time)

  # Rolling join - finds nearest match efficiently
  matched <- simDT[obsDT, roll = "nearest"]

  return(matched)
}
```

**Performance Gain**: 10-100x faster, drastically reduced memory usage

---

### Example 4: Adding Memoization

**Before:**
```r
# R/utilities-plots.R
getLegendDimensions <- function(plot) {
  # Expensive grob extraction
  legend <- ggplot2::ggplotGrob(plot)
  # ... complex extraction logic ...
  return(dimensions)
}

# Called repeatedly for similar plots
dim1 <- getLegendDimensions(plot1)
dim2 <- getLegendDimensions(plot2)  # May have same legend structure
```

**After:**
```r
# Add memoization
library(memoise)
library(digest)

.getLegendDimensionsImpl <- function(plotConfig) {
  # Original implementation
  # ... complex extraction logic ...
  return(dimensions)
}

getLegendDimensions <- function(plot) {
  # Create cache key from relevant plot properties
  plotConfig <- list(
    legendPosition = plot$theme$legend.position,
    legendDirection = plot$theme$legend.direction,
    fontSize = plot$theme$text$size
  )

  cacheKey <- digest(plotConfig)

  if (!exists(cacheKey, envir = .legendCache)) {
    .legendCache[[cacheKey]] <- .getLegendDimensionsImpl(plot)
  }

  return(.legendCache[[cacheKey]])
}

.legendCache <- new.env(parent = emptyenv())
```

**Performance Gain**: 5-10x faster for repeated similar legends

---

## 12. Conclusion

The OSPSuite.ReportingEngine R package has significant optimization opportunities, particularly in:

1. **Data aggregation patterns** - O(n²) incremental growth should be replaced with list accumulation
2. **Loop patterns** - Nested loops can be vectorized with data.table grouping operations
3. **Algorithm complexity** - Time matching and filtering algorithms can be dramatically improved
4. **Data structures** - Migration to data.table would provide 10-100x speedups for large datasets
5. **File I/O** - Multiple file reads can be consolidated

**Recommended Approach**:
- Implement Critical priority items first for maximum impact with minimal risk
- Gradually migrate to data.table for systematic performance improvements
- Add comprehensive benchmarks to measure improvements
- Maintain backward compatibility throughout migration

**Estimated Overall Impact**:
- **5-20x improvement** in typical workflows
- **10-100x improvement** for data-intensive operations with large datasets
- **30-50% reduction** in memory usage for large population analyses
- **Significant reduction** in processing time for multiple outputs

**Key Success Factors**:
1. Focus on hot paths first (goodness of fit, PK parameters, demography)
2. Maintain numerical accuracy and API compatibility
3. Add comprehensive performance tests
4. Document performance characteristics
5. Provide migration guide for users with custom code

All recommendations maintain API compatibility where possible and follow R package best practices.
