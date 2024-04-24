use std::{env, fmt};

use aws_config::meta::region::RegionProviderChain;
use aws_sdk_s3::Client;
use futures::future;
use lambda_http::{Body, Error, Request, RequestExt, Response, run, service_fn};
use lambda_http::aws_lambda_events::query_map::QueryMap;
use tracing::level_filters::LevelFilter;
use tracing_subscriber::EnvFilter;

#[derive(Debug)]
struct Coordinates {
    latitude: f32,
    longitude: f32,
}

impl fmt::Display for Coordinates {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "({}, {})", self.latitude, self.longitude)
    }
}

impl Coordinates {
    fn new(latitude: f32, longitude: f32) -> Self {
        Self {
            latitude,
            longitude,
        }
    }

    fn from_params(params: &QueryMap) -> Self {
        Self {
            latitude: Self::get_and_parse_value_as_float32_from_params(params, "latitude"),
            longitude: Self::get_and_parse_value_as_float32_from_params(params, "longitude"),
        }
    }

    fn get_and_parse_value_as_float32_from_params(params: &QueryMap, key: &str) -> f32 {
        let value_string = match params.first(key) {
            Some(val) => val,
            None => panic!("Couldn't get {} from query string parameters.", key),
        };
        match value_string.parse::<f32>() {
            Ok(val) => val,
            Err(err) => panic!(
                "Couldn't parse value {} to float32: {:?}",
                value_string, err
            ),
        }
    }

    fn get_truncated_coordinates_to_n_decimal_places(&self, places: i32) -> Coordinates {
        Coordinates {
            latitude: Self::truncate_float_to_n_decimal_places(self.latitude, places),
            longitude: Self::truncate_float_to_n_decimal_places(self.longitude, places),
        }
    }

    fn truncate_float_to_n_decimal_places(float: f32, places: i32) -> f32 {
        f32::trunc(float * 10.0_f32.powi(places)) / 10.0_f32.powi(places)
    }
}

async fn function_handler(event: Request, client: &Client) -> Result<Response<Body>, Error> {
    tracing::debug!("Received event: {:?}", event);
    let coordinates = event
        .query_string_parameters_ref()
        .map(Coordinates::from_params)
        .expect("Query string parameters should contain coordinates.");

    // Fetch index file, corresponding to the coordinates from the s3 bucket
    let objects = get_objects(
        client,
        coordinates.get_truncated_coordinates_to_n_decimal_places(2),
    )
        .await?;

    // Return something that implements IntoResponse.
    // It will be serialized to the right response event automatically by the runtime
    let resp = Response::builder()
        .status(200)
        .header("content-type", "text/html")
        .body(Body::from(objects))?;
    Ok(resp)
}

async fn get_objects(client: &Client, coordinates: Coordinates) -> Result<String, anyhow::Error> {
    let bucket =
        env::var("BUCKET_NAME").unwrap_or_else(|_| String::from("restaurantpicker-dev-index"));

    tracing::info!("bucket:      {}", bucket);
    tracing::info!("coordinates: {}", coordinates);

    let neighbors = get_coordinates_neighbors(&coordinates);

    // Send a request for each object in the neighbors list
    let mut object_futures = Vec::new();
    neighbors.iter().for_each(|neighbor| {
        let object_name = format!("{:.2}_{:.2}.json", neighbor.latitude, neighbor.longitude);
        let object = client.get_object().bucket(&bucket).key(object_name).send();
        object_futures.push(object);
    });

    // Collect the results of the object requests
    let mut objects = Vec::new();
    for object in future::join_all(object_futures).await {
        objects.push(match object {
            Ok(obj) => obj,
            Err(err) => {
                tracing::warn!("Couldn't get object: {:?}", err);
                continue;
            }
        });
    }

    // Collect the bytes of the objects
    let mut object_bytes = Vec::new();
    for mut object in objects {
        let mut bytes: Vec<u8> = Vec::new();
        while let Some(byte_item) = object.body.try_next().await? {
            bytes.append(&mut byte_item.to_vec());
        }
        object_bytes.push(bytes);
    }

    Ok(String::from_utf8(concatenate_json_bytes(object_bytes))?)
}

fn concatenate_json_bytes(json_files: Vec<Vec<u8>>) -> Vec<u8> {
    // Initialize an empty Vec<u8> to hold the concatenated bytes
    let mut concatenated_bytes = Vec::new();

    // Iterate over each JSON file
    for json_file in json_files {
        // Check if the first and last bytes are square brackets
        if json_file.starts_with(b"[") && json_file.ends_with(b"]") {
            // Remove the square brackets by slicing the byte slice
            let json_file = &json_file[1..json_file.len() - 1];

            // Add a comma to the end of the concatenated bytes
            let mut json_file_with_comma = Vec::new();
            json_file_with_comma.extend_from_slice(json_file);
            json_file_with_comma.push(b',');

            // Concatenate the bytes
            concatenated_bytes.extend(json_file_with_comma);
        } else {
            // If the JSON file does not start and end with square brackets,
            tracing::warn!("JSON file does not start and end with square brackets.");
        }
    }
    // Add square brackets at the beginning and end
    let mut result = Vec::new();
    result.push(b'[');
    // Remove the last trailing comma
    result.extend_from_slice(&concatenated_bytes[..concatenated_bytes.len() - 1]);
    result.push(b']');

    result
}

fn get_coordinates_neighbors(coordinates: &Coordinates) -> Vec<Coordinates> {
    vec![
        Coordinates::new(coordinates.latitude, coordinates.longitude),
        Coordinates::new(coordinates.latitude + 0.01, coordinates.longitude),
        Coordinates::new(coordinates.latitude - 0.01, coordinates.longitude),
        Coordinates::new(coordinates.latitude, coordinates.longitude + 0.01),
        Coordinates::new(coordinates.latitude, coordinates.longitude - 0.01),
        Coordinates::new(coordinates.latitude + 0.01, coordinates.longitude - 0.01),
        Coordinates::new(coordinates.latitude - 0.01, coordinates.longitude + 0.01),
        Coordinates::new(coordinates.latitude + 0.01, coordinates.longitude + 0.01),
        Coordinates::new(coordinates.latitude - 0.01, coordinates.longitude - 0.01),
    ]
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    let _ = tracing_subscriber::fmt().with_env_filter(
        EnvFilter::builder()
            .with_default_directive(LevelFilter::INFO.into())
            .from_env_lossy(),
    );

    let region_provider = RegionProviderChain::default_provider().or_else("eu-central-1");
    let config = aws_config::defaults(aws_config::BehaviorVersion::v2023_11_09())
        .profile_name("hannesortmeier")
        .region(region_provider)
        .load()
        .await;
    let client = Client::new(&config);

    run(service_fn(|event: Request| async {
        function_handler(event, &client).await
    }))
        .await
}
