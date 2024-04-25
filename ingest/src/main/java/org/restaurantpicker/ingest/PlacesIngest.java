package org.restaurantpicker.ingest;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import software.amazon.awssdk.auth.credentials.ProfileCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;

public class PlacesIngest {

  public static void main(String[] args) throws IOException {

    final Logger logger = LoggerFactory.getLogger(PlacesIngest.class);

    final var apiKey = System.getenv("MAPS_API_KEY");
    if (apiKey == null) {
      throw new RuntimeException("Environment variable MAPs_API_KEY not set");
    }

    try (final var placesClient = new PlacesClient(apiKey)) {
      final var callback = new PlacesSearchCallback();
      try (var in = PlacesIngest.class.getResourceAsStream("/plz_frankfurt.txt")) {
        final var reader = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8));
        for (String line; (line = reader.readLine()) != null; ) {
          var query = "Restaurant " + line;
          logger.info("Getting places with query: " + query);
          placesClient.getPlaces(callback, query);
        }
      }
      final var credentialsProfile = System.getenv("AWS_PROFILE");
      try (final var client =
          S3Client.builder()
              .credentialsProvider(ProfileCredentialsProvider.create(credentialsProfile))
              .region(Region.EU_CENTRAL_1)
              .build()) {
        final var coordinatesToResults = callback.getCoordinatesToResults();
        final var s3Handler = new S3Handler(client);
        s3Handler.updatePlacesBucket(coordinatesToResults);
      }
    }
  }
}
