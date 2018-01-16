resource "aws_iam_role" "master" {
  name = "${coalesce(var.owner, data.external.whoami.result["owner"])}_${data.template_file.cluster_uuid.rendered}_master_iam_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "master" {
  name = "${coalesce(var.owner, data.external.whoami.result["owner"])}_${data.template_file.cluster_uuid.rendered}_master_instance_profile"
  role = "${ aws_iam_role.master.name }"
}

resource "aws_iam_role_policy" "master" {
  name = "${coalesce(var.owner, data.external.whoami.result["owner"])}_${data.template_file.cluster_uuid.rendered}_master_iam_role_policy"
  role = "${ aws_iam_role.master.id }"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
   {
     "Action": [
       "s3:AbortMultipartUpload",
       "s3:DeleteObject",
       "s3:GetBucketAcl",
       "s3:GetBucketPolicy",
       "s3:GetObject",
       "s3:GetObjectAcl",
       "s3:ListBucket",
       "s3:ListBucketMultipartUploads",
       "s3:ListMultipartUploadParts",
       "s3:PutObject",
       "s3:PutObjectAcl"
     ],
     "Resource": "*",
     "Effect": "Allow"
   }
  ]
}
EOF
}
