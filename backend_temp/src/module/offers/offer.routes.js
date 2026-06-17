import { Router } from "express";
import { getOffersHandler, getOffersPreviewHandler } from "./offer.controller.js";

export const offersRouter = Router();

offersRouter.get("/preview", getOffersPreviewHandler);
offersRouter.get("/", getOffersHandler);