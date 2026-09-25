import { configureStore } from "@reduxjs/toolkit";
import { setupListeners } from "@reduxjs/toolkit/query";
import { dappApi } from "./apis/dappApi";
import { gameApi } from "./apis/gameApi";

export const store = configureStore({
  reducer: {
    [dappApi.reducerPath]: dappApi.reducer,
    [gameApi.reducerPath]: gameApi.reducer,
  },
  middleware: (getDefaultMiddleware) => {
    return getDefaultMiddleware().concat(dappApi.middleware, gameApi.middleware);
  },
});

setupListeners(store.dispatch);

export {
  useAddAttractionMutation,
  useFetchAttractionsQuery,
  useUpdateAttractionMutation,
  useRemoveAttractionMutation,
  useFetchAttractionQuery,
  useAddRestaurantMutation,
  useFetchRestaurantsQuery,
  useUpdateRestaurantMutation,
  useRemoveRestaurantMutation,
  useFetchRestaurantQuery,
  useAddShowMutation,
  useFetchShowsQuery,
  useUpdateShowMutation,
  useRemoveShowMutation,
  useFetchShowQuery,
  useFetchParkCompletionQuery,
  useFetchDateGeneratorQuery,
  useFetchCompletedAreasQuery,
  useFetchExperienceCompletionQuery,
  useFetchAnimationCheckListQuery,
} from "./apis/dappApi";
