// Copyright (c) 2023 S44, LLC
// Copyright Contributors to the CitrineOS Project
//
// SPDX-License-Identifier: Apache 2.0

import { IdTokenType, Namespace, CustomDataType, AdditionalInfoType, IdTokenEnumType } from "@citrineos/base";
import { Table, PrimaryKey, Column, DataType, Model, HasMany } from "sequelize-typescript";
import { AdditionalInfo } from "./AdditionalInfo";

@Table
export class IdToken extends Model implements IdTokenType {

    static readonly MODEL_NAME: string = Namespace.IdTokenType;

    declare customData?: CustomDataType;

    @HasMany(() => AdditionalInfo)
    declare additionalInfo?: [AdditionalInfoType, ...AdditionalInfoType[]];

    @Column({
        type: DataType.STRING,
        unique: 'idToken_type'
    })
    declare idToken: string;

    @Column({
        type: DataType.STRING,
        unique: 'idToken_type'
    })
    declare type: IdTokenEnumType;
}
