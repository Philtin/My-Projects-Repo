provider "aws" { 
    region = "us-east-2" 
}

resource "aws_s3_bucket" "newtechnicaltask" { 
  bucket = "newtechnicaltask"  
  acl    = "private"
     
     website {
    index_document = "index.html"  
     }
   } 
resource "aws_s3_bucket_object" "index_object" {  
bucket = "newtechnicaltask"
key    = "index.html"
source = "html/index.html"
acl    = "public-read" 
} 

resource "aws_s3_bucket_object" "error_object" {  
  bucket = "newtechnicaltask" 
  key    = "error.html"
  source = "html/error.html"
  acl    = "public-read"
}


resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  origin {
    domain_name = "aws_s3_bucket.newtechnicaltask.bucket.s3.amazonaws.com" 
    origin_id   = "website"

  }
  
   enabled  = true
   is_ipv6_enabled = true

 
   default_root_object = "index.html"

   default_cache_behavior {
    allowed_methods = [
      "HEAD",
      "GET"
    ]
    cached_methods = [
      "HEAD",
      "GET"
    ]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    default_ttl = 0
    max_ttl     = 0
    min_ttl     = 0
    target_origin_id = "website"
    viewer_protocol_policy = "redirect-to-https" 
    compress = true
  }
   
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods = ["HEAD", "GET"]
    cached_methods = ["HEAD", "GET"]
  
    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
    default_ttl            = 1800
    max_ttl                = 1800
    min_ttl                = 1800
    target_origin_id       = "website"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  viewer_certificate {
   cloudfront_default_certificate = true 
  }

  restrictions {
       geo_restriction {
         restriction_type = "none"
       }
     }
    }

resource "aws_iam_role" "newtechnicaltask_codepipeline" { 
  name = "newtechnicaltask_codepipeline"

  assume_role_policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"  
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
} 

data "aws_iam_policy_document" "tf-cicd-pipeline-policies" {
   
      statement{
        sid = ""
        actions = ["s3:*", "codebuild:*"]
        resources = ["*"]
        effect = "Allow"
    }
}

resource "aws_iam_role_policy" "codepipeline_policy" {  
  name = "codepipeline_policy"
  role = aws_iam_role.newtechnicaltask_codepipeline.name 
  
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl", 
        "cloudfront:GetInvalidation", 
        "s3:PutObject" 
      ],
      "Resource": [ 
         "arn:aws:s3:::newtechnicaltask", 
         "arn:aws:s3:::newtechnicaltask/*" 
      ]
    },
   {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF 
}


resource  "aws_codepipeline" "newtechnicaltask" {  
 
 name  = "newtechnicaltask" 
  role_arn = "arn:aws:iam::016352642720:role/newtechnicaltask_codepipeline"  
  
artifact_store {
    location = "newtechnicaltask" 
    type     = "S3"
  }
 
stage {
    name = "Source" 

    action {
      name             = "Source" 
      category         = "Source"
      owner            = "ThirdParty" 
      provider         = "GitHub" 
      version          = "1" 
      output_artifacts = ["source"]   
      configuration = {

         Owner = var.source_repo_github_owner 
         Repo = var.source_repo_github  
         Branch      = "main" 
         OAuthToken = var.OAuthToken 
         PollForSourceChanges = "true" 
      } 
    }
  }

  
stage {   
    name = "Deploy"

    action {
      name            = "Deploy" 
      category        = "Deploy"
      provider        = "S3"   
      version         = "1"    
      owner           = "AWS" 
     input_artifacts = ["source"] 
      configuration = {
          BucketName = "newtechnicaltask"  
          Extract = "true" 
         
     }
   } 
  }
} 
