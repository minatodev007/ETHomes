import { configureStore, getDefaultMiddleware } from "@reduxjs/toolkit";
import walletReducer from './wallet/wallet.slice';

const store = configureStore({
    reducer: {
        wallet: walletReducer,
    },
    middleware: [...getDefaultMiddleware({ serializableCheck: false })]
});

export default store;