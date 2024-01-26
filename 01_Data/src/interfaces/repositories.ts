// Copyright (c) 2023 S44, LLC
// Copyright Contributors to the CitrineOS Project
//
// SPDX-License-Identifier: Apache 2.0

import { SetVariableDataType, ICrudRepository, SetVariableResultType, AuthorizationData, TransactionEventRequest, ChargingStateEnumType, IdTokenType, VariableAttributeType, ReportDataType, BootConfig, RegistrationStatusEnumType, StatusInfoType, GetVariableResultType, EVSEType, SecurityEventNotificationRequest } from "@citrineos/base";
import { AuthorizationQuerystring } from "./queries/Authorization";
import { Transaction } from "../layers/sequelize/model/TransactionEvent";
import { VariableAttribute } from "../layers/sequelize/model/DeviceModel/VariableAttribute";
import { AuthorizationRestrictions, VariableAttributeQuerystring } from ".";
import { Boot, Authorization, SecurityEvent } from "../layers/sequelize";


export interface IAuthorizationRepository extends ICrudRepository<AuthorizationData> {
    createOrUpdateByQuery(value: AuthorizationData, query: AuthorizationQuerystring): Promise<Authorization | undefined>;
    updateRestrictionsByQuery(value: AuthorizationRestrictions, query: AuthorizationQuerystring): Promise<Authorization | undefined>;
    readByQuery(query: AuthorizationQuerystring): Promise<Authorization | undefined>;
    existsByQuery(query: AuthorizationQuerystring): Promise<boolean>;
    deleteAllByQuery(query: AuthorizationQuerystring): Promise<number>;
}

/**
 * Key is StationId
 */
export interface IBootRepository extends ICrudRepository<BootConfig> {
    createOrUpdateByKey(value: BootConfig, key: string): Promise<Boot | undefined>;
    updateStatusByKey(status: RegistrationStatusEnumType, statusInfo: StatusInfoType | undefined, key: string): Promise<Boot | undefined>;
    updateLastBootTimeByKey(lastBootTime: string, key: string): Promise<Boot | undefined>;
    readByKey(key: string): Promise<Boot | undefined>;
    existsByKey(key: string): Promise<boolean>;
    deleteByKey(key: string): Promise<boolean>;
}

export interface IDeviceModelRepository extends ICrudRepository<VariableAttributeType> {
    createOrUpdateDeviceModelByStationId(value: ReportDataType, stationId: string): Promise<VariableAttribute[]>;
    createOrUpdateByGetVariablesResultAndStationId(getVariablesResult: GetVariableResultType[], stationId: string): Promise<VariableAttribute[]>;
    createOrUpdateBySetVariablesDataAndStationId(setVariablesData: SetVariableDataType[], stationId: string): Promise<VariableAttribute[]>;
    updateResultByStationId(result: SetVariableResultType, stationId: string): Promise<VariableAttribute | undefined>;
    readAllSetVariableByStationId(stationId: string): Promise<SetVariableDataType[]>;
    readAllByQuery(query: VariableAttributeQuerystring): Promise<VariableAttribute[]>;
    existsByQuery(query: VariableAttributeQuerystring): Promise<boolean>;
    deleteAllByQuery(query: VariableAttributeQuerystring): Promise<number>;
}

export interface ISecurityEventRepository extends ICrudRepository<SecurityEvent> {
    createByStationId(value: SecurityEventNotificationRequest, stationId: string): Promise<SecurityEvent | undefined>;
    readByStationIdAndTimestamps(stationId: string, from?: Date, to?: Date): Promise<SecurityEvent[]>;
    deleteByKey(key: string): Promise<boolean>;
}

export interface ITransactionEventRepository extends ICrudRepository<TransactionEventRequest> {
    createOrUpdateTransactionByTransactionEventAndStationId(value: TransactionEventRequest, stationId: string): Promise<Transaction>;
    readAllByStationIdAndTransactionId(stationId: string, transactionId: string): Promise<TransactionEventRequest[]>;
    readTransactionByStationIdAndTransactionId(stationId: string, transactionId: string): Promise<Transaction | undefined>;
    readAllTransactionsByStationIdAndEvseAndChargingStates(stationId: string, evse: EVSEType, chargingStates?: ChargingStateEnumType[]): Promise<Transaction[]>;
    readAllActiveTransactionByIdToken(idToken: IdTokenType): Promise<Transaction[]>;
}