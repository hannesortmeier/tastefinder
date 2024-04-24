# TasteFinder

![TasteFinder.de](taste_finder_de.png)

TasteFinder.de is a cutting-edge, cloud-based application that helps users discover new restaurants based on their
location. Leveraging the power of modern technologies, TasteFinder provides a seamless and intuitive user
experience, making the search for your next dining experience a breeze.

## Getting Started

To get started with TasteFinder, clone the repository and follow the instructions in the individual paragraphs for
each submodule. Make sure you have the necessary environment variables set up and the required permissions for AWS
resources.

## Ingest Module

The `ingest` submodule, written in Java, is responsible for fetching and processing data from external sources. It uses
the Google Places API to gather information about restaurants in various locations. The data is then ingested into an
AWS S3 bucket for further processing and use.

To get started with the `ingest` module, follow these steps:

1. Navigate to the `ingest` directory.
2. Set up your environment variables. You will need to provide your Google Maps API key and AWS credentials.
3. Run the application using Maven: `mvn clean install`.

## Terraform Module

The infrastructure of TasteFinder is managed using Terraform, a popular Infrastructure as Code (IaC) tool. The
Terraform scripts define and provide data for resources such as AWS Lambda for the backend, AWS S3 for data storage,
and AWS Route53 for DNS management. This approach ensures that the infrastructure is easily reproducible, scalable, and
maintainable.

To get started with the `terraform` module, follow these steps:

1. Navigate to the `terraform` directory.
2. Set up your AWS credentials.
3. Initialize Terraform: `terraform init`.
4. Have your domain name ready.
5. Apply the Terraform configuration: `terraform apply`.

## Lambda Module

The `lambda` function, written in Rust, is the heart of our backend. It fetches the ingested data from the S3 bucket,
processes it, and serves it to the frontend. The function is deployed on AWS Lambda, ensuring scalability and
performance.

To get started with the `lambda` module, follow these steps:

1. Navigate to the `lambda` directory.
2. Have your AWS credentials ready.
3. Build the application using Cargo: `cargo lambda build --release`.
4. Test the function locally: `cargo lambda invoke fetch-index --data-file 'test/payload.json' `.
5. Deploy the function to AWS Lambda.

## Frontend Module

The frontend of TasteFinder is a single-page application written in JavaScript. It provides a user-friendly interface
for users to interact with the application. The frontend fetches data from the backend, displays a local restaurant
option.

To get started with the `frontend` module, follow these steps:

1. Navigate to the `frontend` directory.
2. Open the `index.html` file in your browser.

Remember to replace the placeholders with your actual values. Enjoy using TasteFinder!