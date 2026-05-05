"""
CISC 886 - Cloud Computing | Queen's University
PySpark Preprocessing Pipeline for CodeX-2M-Thinking Dataset
Authors: Yomna Algendy, Yasmeen Algendy, Maryam Abdalbary
NetID: 25vrqw
"""

import sys
sys.path.insert(0, "/home/hadoop/.local/lib/python3.9/site-packages")

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, length, rand, lit, when, count
import json
import os
import subprocess

# Initialize Spark
spark = SparkSession.builder.appName("25vrqw-CodeX-Preprocessing").getOrCreate()
print("Spark session started")

# Download dataset from HuggingFace
if not os.path.exists("/tmp/codex_100k.json"):
    from datasets import load_dataset
    print("Downloading dataset...")
    dataset = load_dataset("Modotte/CodeX-2M-Thinking", split="train", streaming=True)

    samples = []
    for i, item in enumerate(dataset):
        if i >= 100000:
            break
        samples.append(item)
        if (i + 1) % 25000 == 0:
            print("Downloaded {} samples".format(i + 1))

    with open("/tmp/codex_100k.json", "w") as f:
        for s in samples:
            f.write(json.dumps(s) + "\n")
    print("Saved to local file")
else:
    print("Data already exists, skipping download")

# Copy to HDFS for distributed access
print("Copying to HDFS...")
subprocess.run(["hdfs", "dfs", "-mkdir", "-p", "/user/hadoop/data"], check=True)
subprocess.run(["hdfs", "dfs", "-put", "-f", "/tmp/codex_100k.json", "/user/hadoop/data/"], check=True)
print("Copied to HDFS")

# Load into Spark DataFrame
df = spark.read.json("hdfs:///user/hadoop/data/codex_100k.json")
print("Loaded into Spark DataFrame")
df.printSchema()
print("Total rows: {}".format(df.count()))

# Step 1: Remove nulls and short rows
print("Step 1: Remove nulls and short rows")
original_count = df.count()
df = df.filter(col("input").isNotNull())
df = df.filter(col("output").isNotNull())
df = df.filter(length(col("input")) > 10)
df = df.filter(length(col("output")) > 10)
cleaned_count = df.count()
print("Before: {}  After: {}  Removed: {}".format(
    original_count, cleaned_count, original_count - cleaned_count))

# Step 2: Add text length columns
print("Step 2: Add text length columns")
df = df.withColumn("input_length", length(col("input")))
df = df.withColumn("output_length", length(col("output")))

# Step 3: Train/Validation/Test split (80/10/10)
print("Step 3: Train/Validation/Test split")
df = df.withColumn("rand_val", rand(seed=42))
df = df.withColumn("split",
    when(col("rand_val") < 0.8, lit("train"))
    .when(col("rand_val") < 0.9, lit("validation"))
    .otherwise(lit("test"))
)
df = df.drop("rand_val")
split_counts = df.groupBy("split").agg(count("*").alias("count"))
split_counts.show()

# Step 4: Save to S3
print("Saving to S3...")
S3_BUCKET = "s3://25vrqw-cisc886-data"
df.filter(col("split") == "train").write.mode("overwrite").parquet(
    S3_BUCKET + "/processed-data/train/")
print("Train saved")
df.filter(col("split") == "validation").write.mode("overwrite").parquet(
    S3_BUCKET + "/processed-data/validation/")
print("Validation saved")
df.filter(col("split") == "test").write.mode("overwrite").parquet(
    S3_BUCKET + "/processed-data/test/")
print("Test saved")

# Step 5: EDA Statistics
print("EDA Statistics:")
df.select("input_length", "output_length").describe().show()
split_counts.show()
print("Total after cleaning: {}".format(df.count()))

print("Preprocessing COMPLETE!")
spark.stop()