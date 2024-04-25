package org.restaurantpicker.ingest;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.google.maps.model.PlacesSearchResult;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

public class S3Handler {

  private static final Logger logger = LoggerFactory.getLogger(S3Handler.class);
  S3Client s3;

  S3Handler(S3Client s3) {
    this.s3 = s3;
  }

  public void updatePlacesBucket(Map<String, List<PlacesSearchResult>> coordinatesToResults) {
    for (var entry : coordinatesToResults.entrySet()) {
      var jsonString = getJsonString(entry.getValue());
      var BUCKET_NAME = System.getenv("BUCKET_NAME");
      putObject(entry.getKey() + ".json", BUCKET_NAME, jsonString);
    }
  }

  private String getJsonString(Object object) {
    var mapper = new ObjectMapper();
    try {
      return mapper.writeValueAsString(object);
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  private int getHashFromJSONString(String jsonString) {
    var mapper = new ObjectMapper();
    JsonFactory factory = mapper.getFactory();
    try {
      var jsonNode = mapper.readTree(factory.createParser(jsonString));
      var jsonObject = (ObjectNode) jsonNode;
      jsonObject.remove("photos");
      jsonObject.remove("openingHours");
      return jsonNode.hashCode();
    } catch (IOException e) {
      logger.error("Error getting hash from JSON string: {}", jsonString);
      throw new RuntimeException(e);
    }
  }

  private void putObject(String key, String bucketName, String jsonString) {
    logger.debug("Writing object to bucket: {}/{}",  bucketName, key);
    var putObjectRequest = PutObjectRequest.builder().bucket(bucketName).key(key).build();
    s3.putObject(putObjectRequest, RequestBody.fromString(jsonString));
  }


  private List<S3Object> getObjectsWithPrefix(String prefix, String bucketName) {
    logger.debug("Getting objects with prefix: {}", "/" + prefix);
    var listObjectsRequest = ListObjectsRequest.builder().bucket(bucketName).prefix(prefix).build();
    var listObjectsResponse = s3.listObjects(listObjectsRequest);
    return listObjectsResponse.contents();
  }
}
