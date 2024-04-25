#!/usr/bin/env python

### Use bioencoder to split the data and train the model 

# Set up dir 
import bioencoder
import os
new_dir = '/home/millerjared/blue_bsc4892/millerjared/ai-taxonomist/'
os.chdir(new_dir)
bioencoder_configure(root_dir=r"bioencoder_wd", run_name="lateral_train_v10")

# create image splits
bioencoder_split_dataset(image_dir=r"/home/millerjared/blue_bsc4892/millerjared/ai-taxonomist/image_sets/lateral-images/", max_ratio=6, random_seed=42, overwrite = True)

# Training 1 
bioencoder_train(config_path=r"/home/millerjared/blue_bsc4892/millerjared/ai-taxonomist/bioencoder_configs/train_stage1.yml")


