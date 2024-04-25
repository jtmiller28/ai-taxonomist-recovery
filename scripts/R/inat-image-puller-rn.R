
### A simple API script to call for phenology data
library("tidyverse")
library("httr")
library("jsonlite")
library(data.table)
# The version for adding images to the file: "https://api.inaturalist.org/v1/observations?has%5B%5D=photos&quality_grade=any&identifications=any&taxon_id=68553&day=24&month=3&year=2019&verifiable=true&spam=false&term_id=12&term_value_id=13&term_value_id=14&term_value_id=15&term_value_id=21"
# No images: "https://api.inaturalist.org/v1/observations?quality_grade=any&identifications=any&taxon_id=68553&day=24&month=3&year=2019&verifiable=true&spam=false&term_id=12&term_value_id=13&term_value_id=14&term_value_id=15&term_value_id=21"
get_obs <- function(max_id){
  # an API call that has "id_above =" at the end
  call <- paste('https://api.inaturalist.org/v1/observations?taxon_id=68553&quality_grade=any&identifications=any&per_page=200&order_by=id&order=asc&id_above=',
                max_id, sep="")
  # making the API call, parsing it to JSON and then flatten
  GET(url = call) %>%
    content(as = "text", encoding = "UTF-8") %>%
    fromJSON(flatten = TRUE) -> get_call_json
  # this grabs just the data we want and makes it a data frame
  as.data.frame(get_call_json$results)
}
# get the first page
obs <- get_obs(max_id = 0) # The iNat page suggests that 10,000 is the upper limit
max_id <- max(obs[["id"]])
thisisalist <- list(page_1 = obs)
page <- 1
while (nrow(obs) == 200) {
  Sys.sleep(0.5)
  page <- page + 1
  page_count <- paste("page", page, sep = "_")
  obs <- get_obs(max_id = max_id)
  thisisalist[[page_count]] <- obs
  max_id <- max(obs[["id"]])
  print(page_count)
  print(max_id)
}
thisisnotalist <- bind_rows(thisisalist)
dim(thisisnotalist)

# We're only interested in records that have >1 image as a first preprocessing filter 
our_data <- thisisnotalist

multiplePhotos <- vector("logical", length = nrow(our_data))

for(i in 1:nrow(our_data)){
  if(nrow(our_data$observation_photos[[i]]) > 1){
    multiplePhotos[i] <- TRUE 
  } else{
    multiplePhotos[i] <- FALSE
  }
}

our_data$multiplePhotos <- multiplePhotos

obs_w_mult_photos <- subset(our_data, our_data$multiplePhotos == TRUE)

## image download


inat_data <- obs_w_mult_photos

downlaod_images_hacked <- function(dat, size = "medium", outpath = "/home/millerjared/blue_bsc4892/millerjared/ai-taxonomist/image_outputs/rn-images/") {
  for (i in 1:dim(dat)[1]) {
    # Create a directory for each observation based on its ID
    observation_dir <- file.path(outpath, paste0("observation_", dat$id[i]))
    dir.create(observation_dir, recursive = TRUE, showWarnings = FALSE)
    # Get image URLs for the current observation
    image_urls <- inat_data$observation_photos[[i]]$photo.url
    #image_urls <- gsub("square.jpeg", "medium.jpeg", image_urls)
    for (j in seq_along(image_urls)) {
      iurl <- gsub("square", size, image_urls[j])
      iname <- file.path(observation_dir, paste0(dat$id[i], "_", j, ".jpg"))
      tryCatch(
        {download.file(iurl, iname, mode = 'wb')},
        error = function(err) {print(paste("MY_ERROR: ", err))}
      )
      Sys.sleep(1)
      print(paste0("image ", j, " of ", length(image_urls), " for observation ", i))
    }
  }
}

#inat_data <- fread("C:/Users/jtmil/OneDrive/Desktop/Research/SoltisLab/phenology-annotations/raw-data/calycoseris-wrightii-082323/observations-352860.csv")

downlaod_images_hacked(inat_data)

list <- list.files("/home/millerjared/blue_bsc4892/millerjared/ai-taxonomist/image_outputs/rn-images/")
usable <- vector("character", length = length(list))
ourSpeciesID <- vector("character", length = length(list))
dorsalImage <- vector("character", length = length(list))
lateralImage <- vector("character", length = length(list))
obs_df <- data.frame(obs_id = list, usable = usable, ourSpeciesID, dorsalImage, lateralImage)
fwrite(obs_df, "/home/millerjared/blue_bsc4892/millerjared/ai-taxonomist/data/processed/annotated-records/rn-pulled-annotations.csv")
