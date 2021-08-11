##Extracting qualitative data for report
library(readxl)
library(tidyverse)

rm(list=ls())

## Number of provision videos through the years
DVD <- read_excel("../Data/sys_ParentalCareRecords.xlsx") %>%
  filter(TypeOfCare=="Prov")
length(unique(DVD$DVDRef))
length(unique(DVD$BroodName))

