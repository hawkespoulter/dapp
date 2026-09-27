import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";
import { API_URL } from "~/constants";
import { getPlayerToken } from "~/components/game/playerStorage";

const withToken = (code) => ({ "X-Player-Token": getPlayerToken(code) || "" });

// Every game action returns the full game state, so write it straight into
// the cached fetchGame result instead of waiting for the next poll.
// Game codes are cached upper-case, matching state.game.code.
const storeState = (pickState = (data) => data) => async (_arg, { dispatch, queryFulfilled }) => {
  try {
    const { data } = await queryFulfilled;
    const state = pickState(data);
    dispatch(gameApi.util.upsertQueryData("fetchGame", state.game.code, state));
  } catch {
    // errors are shown by the component that called the mutation
  }
};

const action = (builder, path, method, body = () => undefined) =>
  builder.mutation({
    query: (arg) => ({ url: `/games/${arg.code}/${path}`, method, headers: withToken(arg.code), body: body(arg) }),
    onQueryStarted: storeState(),
  });

const gameApi = createApi({
  reducerPath: "gameApi",
  baseQuery: fetchBaseQuery({ baseUrl: API_URL }),
  tagTypes: ["GameSettings"],
  endpoints(builder) {
    return {
      fetchGameParks: builder.query({
        providesTags: ["GameSettings"],
        query: () => "/game_parks",
      }),
      fetchGameSettings: builder.query({
        providesTags: ["GameSettings"],
        query: () => "/game_settings",
      }),
      fetchFinishedGames: builder.query({
        providesTags: ["GameSettings"],
        query: (page) => ({ url: "/finished_games", params: { page } }),
      }),
      updateGameSettings: builder.mutation({
        invalidatesTags: ["GameSettings"],
        query: ({ key, settings }) => ({ url: `/game_settings/${key}`, method: "PATCH", body: { settings } }),
      }),
      resetGameSettings: builder.mutation({
        invalidatesTags: ["GameSettings"],
        query: (key) => ({ url: `/game_settings/${key}/reset`, method: "POST" }),
      }),
      fetchGame: builder.query({
        query: (code) => ({ url: `/games/${code}`, headers: withToken(code) }),
      }),
      createGame: builder.mutation({
        query: (body) => ({ url: "/games", method: "POST", body }),
        onQueryStarted: storeState((data) => data.state),
      }),
      joinGame: builder.mutation({
        query: ({ code, name }) => ({ url: `/games/${code}/join`, method: "POST", body: { name } }),
        onQueryStarted: storeState((data) => data.state),
      }),
      startGame: action(builder, "start", "POST"),
      completeChallenge: action(builder, "complete", "POST", ({ challengeId }) => ({ challenge_id: challengeId })),
      buyInfluence: action(builder, "buy", "POST", ({ count }) => ({ count })),
      placeInfluence: action(builder, "place", "POST", ({ area, count }) => ({ area, count })),
      failChallenge: action(builder, "fail", "POST", ({ challengeId }) => ({ challenge_id: challengeId })),
      undoChallenge: action(builder, "undo", "POST"),
      forceVillainTurn: action(builder, "villain_turn", "POST"),
      usePowerUp: action(builder, "power", "POST", ({ power, area }) => ({ power, area })),
      forecastDiscard: action(builder, "forecast", "POST", ({ index }) => ({ index })),
      updateBalance: action(builder, "balance", "PATCH", ({ settings }) => ({ settings })),
    };
  },
});

export const {
  useFetchGameParksQuery,
  useFetchGameSettingsQuery,
  useFetchFinishedGamesQuery,
  useUpdateGameSettingsMutation,
  useResetGameSettingsMutation,
  useFetchGameQuery,
  useCreateGameMutation,
  useJoinGameMutation,
  useStartGameMutation,
  useCompleteChallengeMutation,
  useFailChallengeMutation,
  useUndoChallengeMutation,
  useBuyInfluenceMutation,
  usePlaceInfluenceMutation,
  useForceVillainTurnMutation,
  useUsePowerUpMutation,
  useForecastDiscardMutation,
  useUpdateBalanceMutation,
} = gameApi;

export { gameApi };
