
# Creating EC2 Instance using TF

Firstly, we have to create a EC2 instance (ubuntu) and install jenkins on it. We could have manually created the EC2, but we decided to go ahead with TF, and wrote the TF file.

# Installing Jenkins on EC2 using TF

We decided to install jenkins using TF only, using user_data, which we have tried till now, but jekins is not getting installed via this method.