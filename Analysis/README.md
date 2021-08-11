# Analysis
I tested the silver spoon effect in a population of house sparrows on Lundy Island, UK. I ran bayesian linear mixed effect models using the R package "MCMCglmm" (Hadfield, 2010), on Imperial's research computing service.

Raw data files are not included publically and can be provided upon request.

## Langugae
Deep Meerkat was ran with R 3.6.1

## Dependencies
- MCMCglmm 2.32

## Project Structure
- **Code**: Contains all code used for analysis  
    - DataManip.R: Data manipulation to create final data sets  
    - IndivAnalysis_Cluster: Individual Analysis that is ran on Imperial College's HPC cluster  
    - BroodAnalysis_cluster.R: Brood level analysis that is ran on Imperial College's HPC cluster  
    - RunBroodMCMC.sh/ RunIndivMCMC.sh: Job submission files
    - OrganizeMeerkat.R: Processes all Meerkat data into a dataframe
    - MeerkatFreqCorr.R: Test the correlation between Deep Meerkat and manually annotated data
    - AnalysisFigures.R: Contains all figures included in the thesis regarding analysis results  
**-Jupyters**:Raw model outputs  


## Reference
- **Hadfield, J.D.**, 2010. MCMC methods for multi-response generalized linear mixed models: the MCMCglmm R package. Journal of statistical software 33, 1–22.
- **Imperial Collge Research Computing Service**, n.d.