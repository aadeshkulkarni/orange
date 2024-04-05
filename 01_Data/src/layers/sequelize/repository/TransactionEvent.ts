// Copyright (c) 2023 S44, LLC
// Copyright Contributors to the CitrineOS Project
//
// SPDX-License-Identifier: Apache 2.0

import {
    TransactionEventRequest,
    ChargingStateEnumType,
    IdTokenType,
    TransactionEventEnumType,
    EVSEType
} from "@citrineos/base";
import { ITransactionEventRepository } from "../../../interfaces";
import { MeterValue, Transaction, TransactionEvent } from "../model/TransactionEvent";
import { SequelizeRepository } from "./Base";
import { IdToken } from "../model/Authorization";
import { Evse } from "../model/DeviceModel";
import { Op } from 'sequelize';
import { Model } from "sequelize-typescript";

export class TransactionEventRepository extends SequelizeRepository<TransactionEvent> implements ITransactionEventRepository {
    /**
     * @param value TransactionEventRequest received from charging station. Will be used to create TransactionEvent,
     * MeterValues, and either create or update Transaction. IdTokens (and associated AdditionalInfo) and EVSEs are 
     * assumed to already exist and will not be created as part of this call.
     * 
     * @param stationId StationId of charging station which sent TransactionEventRequest.
     * 
     * @returns Saved TransactionEvent
     */
    async createOrUpdateTransactionByTransactionEventAndStationId(value: TransactionEventRequest, stationId: string): Promise<Transaction> {
        let evse: Evse | undefined = undefined;
        if (value.evse) {
            evse = await this.s.models[Evse.MODEL_NAME]
                .findOne({ where: { id: value.evse.id, connectorId: value.evse.connectorId ? value.evse.connectorId : null } }).then(row => row as Evse);
            if (!evse) {
                evse = await Evse.build({
                    id: value.evse.id,
                    connectorId: value.evse.connectorId ? value.evse.connectorId : null
                }).save();
            }
        }
        const transaction = Transaction.build({
            stationId: stationId,
            isActive: value.eventType !== TransactionEventEnumType.Ended,
            evseDatabaseId: evse ? evse.get('databaseId') : null,
            ...value.transactionInfo
        });
        return this.s.models[Transaction.MODEL_NAME]
            .findOne({ where: { transactionId: transaction.transactionId } }).then(model => {
                if (model) {
                    for (const k in transaction.dataValues) {
                        if (k !== 'id') { // id is not a field that can be updated
                            const newValue = transaction.getDataValue(k);
                            // Certain fields, such as charging state, may be updated with null
                            // In current version of ocpp (2.0.1) this is purposeful as charging state doesn't have an 'unplug' state--null is used instead
                            // This is not ideal, and will hopefully be addressed in future versions.
                            model.setDataValue(k, newValue);
                        }
                    }
                    return model.save();
                } else {
                    return transaction.save();
                }
            }).then(model => {
                const transactionDatabaseId = (model as Model<any, any>).id;
                const event = TransactionEvent.build({
                    stationId: stationId,
                    transactionDatabaseId: transactionDatabaseId,
                    ...value
                }, { include: [MeterValue] });
                event.meterValue?.forEach(meterValue => meterValue.transactionDatabaseId = transactionDatabaseId);
                super.create(event);
                return model as Transaction;
            });
    }

    readAllByStationIdAndTransactionId(stationId: string, transactionId: string): Promise<TransactionEventRequest[]> {
        return super.readAllByQuery({
            where: { stationId: stationId },
            include: [{ model: Transaction, where: { transactionId: transactionId } }, MeterValue, Evse, IdToken]
        },
            TransactionEvent.MODEL_NAME).then(transactionEvents => {
                transactionEvents?.forEach(transactionEvent => transactionEvent.transaction = undefined);
                return transactionEvents;
            });
    }

    readTransactionByStationIdAndTransactionId(stationId: string, transactionId: string): Promise<Transaction | undefined> {
        return this.s.models[Transaction.MODEL_NAME].findOne({
            where: { stationId: stationId, transactionId: transactionId },
            include: [MeterValue]
        })
            .then(row => (row as Transaction));
    }

    /**
     * @param stationId StationId of the charging station where the transaction took place.
     * @param evse Evse where the transaction took place.
     * @param chargingStates Optional list of {@link ChargingStateEnumType}s the transactions must be in. 
     * If not present, will grab transactions regardless of charging state. If not present, will grab transactions 
     * without charging states, such as transactions started when a parking bay occupancy detector detects 
     * an EV (trigger reason "EVDetected")
     * 
     * @returns List of transactions which meet the requirements.
     */
    readAllTransactionsByStationIdAndEvseAndChargingStates(stationId: string, evse?: EVSEType, chargingStates?: ChargingStateEnumType[] | undefined): Promise<Transaction[]> {
        const includeObj = evse ? [{ model: Evse, where: { id: evse.id, connectorId: evse.connectorId ? evse.connectorId : null } }] : [];
        return this.s.models[Transaction.MODEL_NAME].findAll({
            where: { stationId: stationId, ...(chargingStates ? { chargingState: { [Op.in]: chargingStates } } : {}) },
            include: includeObj
        }).then(row => (row as Transaction[]));
    }

    readAllActiveTransactionsByIdToken(idToken: IdTokenType): Promise<Transaction[]> {
        return this.s.models[Transaction.MODEL_NAME].findAll({
            where: { isActive: true },
            include: [{
                model: TransactionEvent,
                include: [{
                    model: IdToken, where: {
                        idToken: idToken.idToken,
                        type: idToken.type
                    }
                }]
            }]
        })
            .then(row => (row as Transaction[]));
    }

    readAllMeterValuesByTransactionDataBaseId(transactionDataBaseId: number): Promise<MeterValue[]> {
        return this.s.models[MeterValue.MODEL_NAME].findAll({
            where: { transactionDatabaseId: transactionDataBaseId }
        })
            .then(row => (row as MeterValue[]));
    }
}