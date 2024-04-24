package org.restaurantpicker.ingest;

import com.google.maps.GeoApiContext;
import com.google.maps.PlacesApi;
import com.google.maps.TextSearchRequest;
import java.io.IOException;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PlacesClient implements AutoCloseable {
    private static final Logger logger = LoggerFactory.getLogger(PlacesClient.class);
    private final GeoApiContext context;

    PlacesClient(String apiKey) {
        this.context =  new GeoApiContext.Builder().apiKey(apiKey).build();
    }

    public static TextSearchRequest getNextPage(GeoApiContext context, String nextPageToken) {
        // Check if it is possible to find out, when the next page is ready
        try {
            Thread.sleep( 2000 );
        } catch (InterruptedException e) {
            throw new RuntimeException(e);
        }
        return PlacesApi.textSearchNextPage(context, nextPageToken);
    }

    public void getPlaces(PlacesSearchCallback callback, String query) {
            Optional<String> nextPageToken = Optional.empty();
            do {
                logger.debug("Making request with npt: " + nextPageToken.orElse("null"));
                final var request = nextPageToken
                        .map(token -> getNextPage(context, token))
                        .orElseGet(() -> PlacesApi.textSearchQuery(context, query));
                try {
                    final var response = request.await();
                    callback.execute(response);
                    nextPageToken = Optional.ofNullable(response.nextPageToken);
                } catch (Exception e) {
                    throw  new RuntimeException(e);
                }
                } while (nextPageToken.isPresent());
    }

    @Override
    public void close() throws IOException {
        context.close();
    }

}