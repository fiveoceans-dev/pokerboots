/**
 * Reducer Composition Pattern
 * 
 * This module provides a unified interface to all specialized reducer modules.
 * It maintains backward compatibility with the monolithic reducer while 
 * organizing code into focused, testable modules.
 */

import {
  Table,
  PokerEvent,
  StateTransition,
} from "../types";

// Import all specialized reducer functions
import { startHand, postBlinds, endHand } from "./handLifecycle";
import { applyHoleCards, enterStreet } from "./cardDealing";
import { applyAction, handleTimeoutAutoFold } from "./actionProcessing";
import { closeStreet, processShowdown, processPayout } from "./potManagement";
import { addPlayer, removePlayer, sitOutPlayer, sitInPlayer } from "./tableManagement";

/**
 * Main reducer function - pure and deterministic
 * Processes events and returns new table state with side effects
 */
export function reduce(table: Table, event: PokerEvent): StateTransition {
  switch (event.t) {
    case "StartHand":
      return startHand(table, event.handNumber, event.timestamp);

    case "PostBlinds":
      return postBlinds(table, event.sb, event.bb, event.ante);

    case "DealHole":
      return applyHoleCards(table, event.cards);

    case "EnterStreet":
      return enterStreet(table, event.street, event.cards, event.isAutoDealt);

    case "Action":
      return applyAction(table, event.seat, event.action, event.amount);

    case "TimeoutAutoFold":
      return handleTimeoutAutoFold(table, event.seat);

    case "CloseStreet":
      return closeStreet(table);

    case "Showdown":
      return processShowdown(table, event.results);

    case "Payout":
      return processPayout(table, event.distributions);

    case "HandEnd":
      return endHand(table);


    case "PlayerJoin":
      return addPlayer(
        table,
        event.seat,
        event.pid,
        event.chips,
        event.nickname,
      );

    case "PlayerLeave":
      return removePlayer(table, event.seat, event.pid);

    case "PlayerSitOut":
      return sitOutPlayer(table, event.seat, event.pid, event.reason);

    case "PlayerSitIn":
      return sitInPlayer(table, event.seat, event.pid);

    default:
      // TypeScript ensures all cases are handled
      return { nextState: table, sideEffects: [] };
  }
}

// Export individual reducer functions for direct usage and testing
export {
  // Hand lifecycle
  startHand,
  postBlinds,
  endHand,
  
  // Card dealing
  applyHoleCards,
  enterStreet,
  
  // Action processing
  applyAction,
  handleTimeoutAutoFold,
  
  // Pot management
  closeStreet,
  processShowdown,
  processPayout,
  
  // Table management
  addPlayer,
  removePlayer,
  sitOutPlayer,
  sitInPlayer,
};

// Export types for convenience
export type { StateTransition } from "../types";
