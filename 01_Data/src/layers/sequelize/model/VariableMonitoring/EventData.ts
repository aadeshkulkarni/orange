// Copyright Contributors to the CitrineOS Project
//
// SPDX-License-Identifier: Apache 2.0
import {
    ComponentType,
    CustomDataType,
    EventDataType,
    EventNotificationEnumType,
    EventTriggerEnumType,
    Namespace,
    VariableType
} from "@citrineos/base";
import {BelongsTo, Column, DataType, ForeignKey, Index, Model, Table} from "sequelize-typescript";
import {Component, Variable} from "../DeviceModel";

@Table
export class EventData extends Model implements EventDataType {
    static readonly MODEL_NAME: string = Namespace.EventDataType;
    declare customData?: CustomDataType;

    /**
     * Fields
     */
    @Index
    @Column({
        unique: 'stationId'
    })
    declare stationId: string;

    @Column(DataType.INTEGER)
    declare eventId: number;
    declare timestamp: string;

    @Column(DataType.STRING)
    declare trigger: EventTriggerEnumType;

    @Column(DataType.INTEGER)
    declare cause?: number;

    declare actualValue: string;

    declare techCode?: string;

    declare techInfo?: string;

    @Column(DataType.BOOLEAN)
    declare cleared?: boolean;
    declare transactionId?: string;

    @Column(DataType.INTEGER)
    declare variableMonitoringId?: number;

    @Column(DataType.STRING)
    declare eventNotificationType: EventNotificationEnumType;

    /**
     * Relations
     */
    @BelongsTo(() => Variable)
    declare variable: VariableType;

    @ForeignKey(() => Variable)
    @Column({
        type: DataType.INTEGER,
    })
    declare variableId?: number;

    @BelongsTo(() => Component)
    declare component: ComponentType;

    @ForeignKey(() => Component)
    @Column({
        type: DataType.INTEGER,
    })
    declare componentId?: number;
}