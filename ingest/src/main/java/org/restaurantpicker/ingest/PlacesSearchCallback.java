package org.restaurantpicker.ingest;

import com.google.maps.model.PlacesSearchResponse;
import com.google.maps.model.PlacesSearchResult;
import java.util.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PlacesSearchCallback {

    private static final Logger logger = LoggerFactory.getLogger(PlacesSearchCallback.class);

    private final Map<String, List<PlacesSearchResult>> coordinatesToResults = new HashMap<>();

    PlacesSearchCallback() {}

    public void execute(PlacesSearchResponse response) {
        logger.debug("Got response with " + response.results.length + " results");
        logger.debug("Mapping results to coordinates");
        Arrays.stream(response.results).forEach(this::mapResultsToCoordinates);
    }

    private void mapResultsToCoordinates(PlacesSearchResult result) {
        var lat = (Math.floor(result.geometry.location.lat * 100) / 100);
        var lng = (Math.floor(result.geometry.location.lng * 100) / 100);
        var key = lat + "_" + lng;
        if (coordinatesToResults.containsKey(key)) {
            coordinatesToResults.get(key).add(result);
        } else {
            coordinatesToResults.put(key, new ArrayList<>(List.of(result)));
        }
    }

    public Map<String, List<PlacesSearchResult>> getCoordinatesToResults() {
        return coordinatesToResults;
    }

}
