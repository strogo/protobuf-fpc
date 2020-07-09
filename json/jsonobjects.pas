{ interface library for FPC and Lazarus

  Copyright (C) 2019-2020 Lagunov Aleksey alexs75@yandex.ru

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version with the following modification:

  As a special exception, the copyright holders of this library give you
  permission to link this library with independent modules to produce an
  executable, regardless of the license terms of these independent modules,and
  to copy and distribute the resulting executable under terms of your choice,
  provided that you also meet, for each linked independent module, the terms
  and conditions of the license of that module. An independent module is a
  module which is not derived from or based on this library. If you modify
  this library, you may extend this exception to your version of the library,
  but you are not obligated to do so. If you do not wish to do so, delete this
  exception statement from your version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}

unit JSONObjects;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, xmlobject, TypInfo, fpJSON, AbstractSerializationObjects;

type

  { TJSONSerializationObject }

  TJSONSerializationObject = class(TAbstractSerializationObject)
  private
    FDoc: TJSONObject;
    FJSONName: string;
    procedure SetJSONName(AValue: string);

    function DefaultObjectList:TXmlSerializationObjectList;
  protected
    procedure InternalReadDoc; override;

    procedure InternalWriteString(P: TPropertyDef; AValue:string); override;
    procedure InternalWriteBoolean(P: TPropertyDef; AValue:Boolean); override;
    procedure InternalWriteInteger(P: TPropertyDef; AValue:Integer); override;
    procedure InternalWriteInt64(P: TPropertyDef; AValue:Int64); override;
    procedure InternalWriteQWord(P: TPropertyDef; AValue:QWord); override;
    procedure InternalWriteDateTime(P: TPropertyDef; AValue:TDateTime); override;
    procedure InternalWriteDate(P: TPropertyDef; AValue:TDate); override;
    procedure InternalWriteTime(P: TPropertyDef; AValue:TTime); override;
    procedure InternalWriteFloat(P: TPropertyDef; AValue:Double); override;
    procedure InternalWriteDynArray(P: TPropertyDef; AProp:PPropInfo); override;

    procedure InternalWriteClass(P: TPropertyDef; AObject:TAbstractSerializationObject); override;
    procedure InternalWriteClassCollection(P: TPropertyDef; AObjects:TXmlSerializationObjectList); override;
  public
    procedure LoadFromStream(AStream:TStream); override;
    procedure SaveToStream(AStream:TStream); override;

    property JSONName:string read FJSONName write SetJSONName;
  end;

implementation
uses xmlobject_resource, jsonparser;

type
  TXmlSerializationObjectListHack = class(TXmlSerializationObjectList);

{ TJSONSerializationObject }

procedure TJSONSerializationObject.SetJSONName(AValue: string);
begin
  if FJSONName=AValue then Exit;
  FJSONName:=AValue;
end;

function TJSONSerializationObject.DefaultObjectList: TXmlSerializationObjectList;
var
  P: TPropertyDef;
  FInst: TObject;
  FProp: PPropInfo;
  K: TTypeKind;
begin
  Result:=nil;
  for P in PropertyList do
  begin
    if xsaDefault in P.Attribs then
    begin
      FProp:=GetPropInfo(Self, P.PropertyName); //Retreive property informations
      K:=FProp^.PropType^.Kind;
      FInst := TObject(PtrInt( GetOrdProp(Self, FProp)));
      if FInst is TXmlSerializationObjectList then
        Result:=TXmlSerializationObjectList(FInst);
      Exit;
    end;
  end;
end;

procedure TJSONSerializationObject.InternalReadDoc;

procedure DoInObject(AName:string; AList:TXmlSerializationObjectList; J:TJSONObject);
var
  R: TJSONSerializationObject;
begin
  R:=TXmlSerializationObjectListHack(AList).InternalAddObject as TJSONSerializationObject;
  R.JSONName:=AName;
  R.FDoc:=J;
  R.InternalReadDoc;
  R.FDoc:=nil;
end;

var
  J: TJSONData;
  S: String;
  i: Integer;
  P: TPropertyDef;
  FProp: PPropInfo;
  K: TTypeKind;
  FInst: TObject;
begin
  for i:=0 to FDoc.Count-1 do
  begin
    S:=FDoc.Names[i];
    J:=FDoc.Items[i];
    if J is TJSONArray then
    else
    if J is TJSONObject then
    begin
      P:=PropertyList.PropertyByXMLName(S);
      if Assigned(P) then
      begin
        FProp:=GetPropInfo(Self, P.PropertyName); //Retreive property informations
        K:=FProp^.PropType^.Kind;

        FInst := TObject(PtrInt( GetOrdProp(Self, FProp)));
        if not Assigned(FInst) then
          raise Exception.CreateFmt(sClassPropertyNotInit, [P.PropertyName]);
        if FInst is TJSONSerializationObject then
        begin
          TJSONSerializationObject(FInst).FDoc:=J as TJSONObject;
          TJSONSerializationObject(FInst).InternalReadDoc;
          TJSONSerializationObject(FInst).FDoc:=nil;
        end
        else
        if FInst is TXmlSerializationObjectList then
          DoInObject('', TXmlSerializationObjectListHack(FInst), J as TJSONObject);
      end
      else
      begin
        if Assigned(DefaultObjectList) then
          DoInObject(S, DefaultObjectList, J as TJSONObject);
      end
    end
    else
    begin
      InternalReadString(S, J.AsString);
    end;
  end;
end;

procedure TJSONSerializationObject.InternalWriteString(P: TPropertyDef;
  AValue: string);
begin
  FDoc.Add(P.XMLName, TJSONString.Create(AValue));
end;

procedure TJSONSerializationObject.InternalWriteBoolean(P: TPropertyDef;
  AValue: Boolean);
begin
  FDoc.Add(P.XMLName, TJSONBoolean.Create(AValue));
end;

procedure TJSONSerializationObject.InternalWriteInteger(P: TPropertyDef;
  AValue: Integer);
begin
  FDoc.Add(P.XMLName, TJSONIntegerNumber.Create(AValue));
end;

procedure TJSONSerializationObject.InternalWriteInt64(P: TPropertyDef;
  AValue: Int64);
begin
  FDoc.Add(P.XMLName, TJSONInt64Number.Create(AValue));
end;

procedure TJSONSerializationObject.InternalWriteQWord(P: TPropertyDef;
  AValue: QWord);
begin
  FDoc.Add(P.XMLName, TJSONQWordNumber.Create(AValue));
end;

procedure TJSONSerializationObject.InternalWriteDateTime(P: TPropertyDef;
  AValue: TDateTime);
begin
  FDoc.Add(P.XMLName, TJSONString.Create(DateTimeToStr(AValue)));
end;

procedure TJSONSerializationObject.InternalWriteDate(P: TPropertyDef;
  AValue: TDate);
begin
  FDoc.Add(P.XMLName, TJSONString.Create(DateToStr(AValue)));
end;

procedure TJSONSerializationObject.InternalWriteTime(P: TPropertyDef;
  AValue: TTime);
begin
  FDoc.Add(P.XMLName, TJSONString.Create(TimeToStr(AValue)));
end;

procedure TJSONSerializationObject.InternalWriteFloat(P: TPropertyDef;
  AValue: Double);
begin
  FDoc.Add(P.XMLName, TJSONFloatNumber.Create(AValue));
end;

procedure TJSONSerializationObject.InternalWriteDynArray(P: TPropertyDef;
  AProp: PPropInfo);
var
  FJA: TJSONArray;
  FDinArray: TObject;
  L: tdynarrayindex;
  PDT: PTypeData;
  O: TOrdType;
  K: TTypeKind;
  i: Integer;
begin
  FDinArray:=GetObjectProp(Self, AProp);
  L:=DynArraySize(FDinArray);
  PDT:=GetTypeData(AProp^.PropType);
  O:=PDT^.OrdType;
  K:=PDT^.ElType2^.Kind;
  if not (K in [tkInteger, tkString, tkAString]) then
    raise exception.CreateFmt(sUknowPropertyType, [P.PropertyName]);

  FJA:=TJSONArray.Create;
  FDoc.Add(P.XMLName, FJA);

  for i:=0 to L-1 do
  begin
    case K of
      tkInteger:
      begin
        case O of
          //  otSByte,otUByte,otSWord,otUWord,
            otSLong:FJA.Add(TXSDIntegerArray(FDinArray)[i]);
            //otULong,otSQWord,otUQWor
        else
          raise exception.CreateFmt(sUknowPropertyType, [P.PropertyName]);
        end;
      end;
      tkAString,
      tkString:FJA.Add(TXSDStringArray(FDinArray)[i]);
    else
      raise exception.CreateFmt(sUknowPropertyType, [P.PropertyName]);
    end;
  end;
end;

procedure TJSONSerializationObject.InternalWriteClass(P: TPropertyDef;
  AObject: TAbstractSerializationObject);
begin
  if not Assigned(AObject) then Exit;
  TJSONSerializationObject(AObject).FDoc:=TJSONObject.Create;
  FDoc.Add(P.XMLName, TJSONSerializationObject(AObject).FDoc);
  TJSONSerializationObject(AObject).InternalWriteDoc;
  TJSONSerializationObject(AObject).FDoc:=Nil;
end;

procedure TJSONSerializationObject.InternalWriteClassCollection(
  P: TPropertyDef; AObjects: TXmlSerializationObjectList);
var
  i: Integer;
  FJA: TJSONArray;
  FItem: TJSONSerializationObject;
begin
  if xsaDefault in P.Attribs then
  begin
    for i:=0 to AObjects.Count-1 do
    begin
      FItem:=TXmlSerializationObjectListHack(AObjects).InternalGetItem(i) as TJSONSerializationObject;
      FItem.FDoc:=TJSONObject.Create;
      FDoc.Add(FItem.JSONName, FItem.FDoc);
      FItem.InternalWriteDoc;
      FItem.FDoc:=nil;
    end;
  end
  else
  begin
    FJA:=TJSONArray.Create;
    FDoc.Add(P.XMLName, FJA);

    for i:=0 to AObjects.Count-1 do
    begin
      FItem:=TXmlSerializationObjectListHack(AObjects).InternalGetItem(i) as TJSONSerializationObject;
      FItem.FDoc:=TJSONObject.Create;
      FJA.Add(FItem.FDoc);
      FItem.InternalWriteDoc;
      FItem.FDoc:=nil;
    end;
  end;
end;

procedure TJSONSerializationObject.LoadFromStream(AStream: TStream);
var
  P: TJSONParser;
begin
  P:=TJSONParser.Create(AStream);
  try
    FDoc:=P.Parse as TJSONObject;
    InternalReadDoc;
    FDoc.Free;
  finally
    P.Free;
  end;
end;

procedure TJSONSerializationObject.SaveToStream(AStream: TStream);
var
  S: TJSONStringType;
  JO: TJSONString;
begin
  FDoc:=TJSONObject.Create;
  try
    InternalWriteDoc;
    S:=FDoc.FormatJSON;
    if S<>'' then
      AStream.Write(S[1], Length(S));
  finally
    FreeAndNil(FDoc);
  end;
end;

end.
