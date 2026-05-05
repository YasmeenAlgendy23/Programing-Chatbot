\# Cloud-Based Programming Chatbot Using Fine-Tuned LLM on AWS



\*\*CISC 886 — Cloud Computing | Queen's University | May 2026\*\*



\*\*Authors:\*\* Yomna Algendy, Yasmeen Algendy, Maryam Abdalbary



---



\## Project Overview



End-to-end pipeline for deploying a programming chatbot on AWS. Fine-tunes CodeLlama-7B-Instruct using QLoRA on the CodeX-2M-Thinking dataset (2M+ samples) and deploys via Ollama with Open WebUI.



| Phase | Result |

|-------|--------|

| Infrastructure | 24 AWS resources via Terraform |

| Preprocessing | 100K samples on EMR Spark, 80/10/10 split |

| Fine-Tuning | QLoRA 1.13% trainable, loss 1.3708 to 1.0440 (23.8%), 49.3 min |

| Deployment | 3.8 GB Q4\\\_0 via Ollama on EC2 t3.xlarge |

| Interface | Open WebUI with auth and code rendering |

| Cost | ~$0.81 total AWS |



---



\## Architecture



```

Users --> IGW --> VPC 10.0.0.0/16

&nbsp;                 |-- Subnet 1 (10.0.1.0/24, us-east-1a)

&nbsp;                 |    |-- EC2 t3.xlarge

&nbsp;                 |    |    |-- Ollama :11434 (codellama:7b-instruct, 3.8GB)

&nbsp;                 |    |    |-- OpenWebUI :3000

&nbsp;                 |    |-- EMR Cluster (transient)

&nbsp;                 |         |-- 1 Master + 2 Core m5.xlarge

&nbsp;                 |         |-- Spark 3.5.0, EMR 7.0.0

&nbsp;                 |-- Subnet 2 (10.0.2.0/24, us-east-1b)

&nbsp;                 |-- S3: 25vrqw-cisc886-data

&nbsp;                      |-- raw-data/

&nbsp;                      |-- processed-data/ (train/val/test)

&nbsp;                      |-- model/

&nbsp;                      |-- scripts/



External:

&nbsp; HuggingFace --> CodeX-2M-Thinking (2M+ samples)

&nbsp; Kaggle T4   --> QLoRA fine-tuning (50K samples, 200 steps)

```



---



\## Repository Structure



```

Programing-Chatbot/

├── terraform/

│   ├── variables.tf          # netid, region, enable toggles

│   ├── main.tf               # VPC, subnets, IGW, route table, keys

│   ├── security\_groups.tf    # EC2, EMR Master, EMR Core SGs

│   ├── s3.tf                 # S3 bucket and folders

│   ├── iam.tf                # EMR roles and instance profile

│   ├── emr.tf                # Conditional EMR cluster

│   ├── ec2.tf                # Conditional EC2 instance

│   └── outputs.tf            # VPC, S3, EMR, EC2 outputs

├── scripts/

│   └── preprocessing.py      # PySpark pipeline

├── notebooks/

│   └── fine\_tuning.ipynb     # Kaggle QLoRA notebook

├── report/

│   ├── main.tex              # LaTeX report

│   └── images/               # Screenshots

├── README.md

└── .gitignore

```



---



\## Technology Stack



| Component | Technology |

|-----------|-----------|

| IaC | Terraform (AWS Provider) |

| Cloud | AWS VPC, EC2, S3, EMR, IAM |

| Processing | Apache Spark 3.5.0 on EMR 7.0.0 |

| Model | CodeLlama-7B-Instruct-hf (Meta) |

| Fine-Tuning | QLoRA 4-bit NF4 via PEFT + TRL |

| Dataset | CodeX-2M-Thinking (Modotte/HuggingFace) |

| Serving | Ollama REST API :11434 |

| Interface | Open WebUI Docker :3000 |

| Training | Kaggle NVIDIA T4 (free) |



---



\## Setup



\### 1. Clone



```bash

git clone https://github.com/YasmeenAlgendy23/Programing-Chatbot.git

cd Programing-Chatbot

```



\### 2. AWS Credentials



```bash

export AWS\_ACCESS\_KEY\_ID="your\_key"

export AWS\_SECRET\_ACCESS\_KEY="your\_secret"

export AWS\_DEFAULT\_REGION="us-east-1"

```



\### 3. Base Infrastructure



```bash

cd terraform

terraform init

terraform apply

```



\### 4. EMR Preprocessing



```bash

terraform apply -var="enable\_emr=true"

ssh -i 25vrqw-key.pem hadoop@<EMR\_DNS>

spark-submit preprocessing.py

exit

terraform apply -var="enable\_emr=false"

```



\### 5. Fine-Tune (Kaggle)



Upload `notebooks/fine\_tuning.ipynb` to Kaggle. Select GPU T4, enable Internet. Run all cells (~50 min). Download adapter.



\### 6. EC2 Deployment



```bash

terraform apply -var="enable\_ec2=true"

ssh -i 25vrqw-key.pem ec2-user@<EC2\_IP>



\# Ollama

sudo yum install -y zstd

curl -fsSL https://ollama.com/install.sh | sh

ollama pull codellama:7b-instruct



\# Ollama Docker config

sudo mkdir -p /etc/systemd/system/ollama.service.d

echo '\[Service]

Environment="OLLAMA\_HOST=0.0.0.0"' | \\

&nbsp; sudo tee /etc/systemd/system/ollama.service.d/override.conf

sudo systemctl daemon-reload \&\& sudo systemctl restart ollama



\# OpenWebUI

sudo yum install -y docker

sudo systemctl start docker \&\& sudo systemctl enable docker

sudo docker run -d -p 3000:8080 \\

&nbsp; -e OLLAMA\_BASE\_URL=http://172.17.0.1:11434 \\

&nbsp; --add-host=host.docker.internal:host-gateway \\

&nbsp; -v open-webui:/app/backend/data \\

&nbsp; --name open-webui --restart always \\

&nbsp; ghcr.io/open-webui/open-webui:main

```



\### 7. Access



```

http://<EC2\_IP>:3000

```



\### 8. Cleanup



```bash

exit

terraform apply -var="enable\_ec2=false"

terraform destroy

```



---



\## Fine-Tuning



| Parameter | Value |

|-----------|-------|

| Model | codellama/CodeLlama-7b-Instruct-hf (7B) |

| Method | QLoRA 4-bit NF4 |

| LoRA Rank / Alpha | 16 / 16 |

| Trainable | 39,976,960 / 3,540,520,960 (1.13%) |

| VRAM | 1.71 GB |

| Dataset | 50,000 samples |

| Steps | 200 |

| Batch | 2 x 2 = 4 effective |

| LR | 2e-4 cosine |

| Precision | bf16 |

| Time | 49.3 min |

| Loss | 1.3708 to 1.0440 (23.8% reduction) |

| Adapter | 79.8 MB |

| Platform | Kaggle T4 (free) |



---



\## Preprocessing



| Metric | Value |

|--------|-------|

| Cluster | 25vrqw-emr-spark, EMR 7.0.0, Spark 3.5.0 |

| Nodes | 1 Master + 2 Core m5.xlarge |

| Elapsed | 48 min 30 sec |

| Samples | 100,000 (0 removed) |

| Input mean / range | 1,357 / 33--22,378 chars |

| Output mean / range | 25,303 / 863--91,750 chars |

| Train / Val / Test | 79,997 / 9,927 / 10,076 |



---



\## Cost



| Service | Rate | Duration | Cost |

|---------|------|----------|------|

| EMR 3x m5.xlarge | $0.58/hr | 48 min | $0.46 |

| EC2 t3.xlarge | $0.17/hr | 2 hr | $0.34 |

| S3 | $0.023/GB | <1 GB | <$0.01 |

| Kaggle T4 | Free | 49 min | $0.00 |

| \*\*Total\*\* | | | \*\*~$0.81\*\* |



---



\## Challenges



| Problem | Solution |

|---------|----------|

| Unsloth version conflicts | Switched to HuggingFace PEFT + TRL |

| Colab RAM exceeded 12.7 GB | Migrated to Kaggle 30 GB |

| EMR rejects public ports != 22 | Removed Spark UI from SG |

| Workers can't read local files | Used hdfs dfs -put |

| TRL 1.3.0 API changes | Used SFTConfig, processing\\\_class |

| GPU vCPU quota = 0 | Used t3.xlarge CPU |

| Ollama unreachable from Docker | OLLAMA\\\_HOST=0.0.0.0 + bridge 172.17.0.1 |

| Amazon Linux 2 GLIBC old | Switched to AL2023 |



---



\## References



1\. Roziere et al., "Code Llama: Open Foundation Models for Code," arXiv:2308.12950, 2023

2\. Dettmers et al., "QLoRA: Efficient Finetuning of Quantized Language Models," NeurIPS, 2023

3\. Hu et al., "LoRA: Low-Rank Adaptation of Large Language Models," arXiv:2106.09685, 2021

4\. Touvron et al., "LLaMA 2," arXiv:2307.09288, 2023

5\. Modotte, "CodeX-2M-Thinking," HuggingFace, 2024

6\. HashiCorp Terraform, 2024

7\. Apache Spark, 2024

8\. AWS EMR / EC2, 2024

9\. Ollama, 2024

10\. Open WebUI, 2024



---



CISC 886 — Cloud Computing | Queen's University | May 2026

