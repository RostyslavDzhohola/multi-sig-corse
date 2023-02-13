import React, { useCallback, useEffect, useState } from "react";
import { Button, List, Modal, Input, Card, DatePicker, Slider, Switch, Progress, Spin } from "antd";
import { SyncOutlined } from "@ant-design/icons";
import { parseEther, formatEther } from "@ethersproject/units";
import { ethers } from "ethers";
import QR from "qrcode.react";
import { useContractReader, useEventListener, useLocalStorage, useLookupAddress } from "../hooks";
import { Address, AddressInput, Balance, Blockie, Events, TransactionListItem } from "../components";

const axios = require("axios");

export default function FrontPage({
  executeTransactionEvents,
  contractName,
  localProvider,
  readContracts,
  price,
  mainnetProvider,
  blockExplorer,
}) {
  if (!Array.isArray(executeTransactionEvents)) {
    console.error("Unexpected result from useEventListener:", executeTransactionEvents);
  }
  const [methodName, setMethodName] = useLocalStorage("addSigner");
  return (
    <div style={{ padding: 32, maxWidth: 750, margin: "auto" }}>
      <div style={{ paddingBottom: 32 }}>
        <div>
          <Balance
            address={readContracts ? readContracts[contractName].address : readContracts}
            provider={localProvider}
            dollarMultiplier={price}
            fontSize={64}
          />
        </div>
        <div>
          <QR
            value={readContracts ? readContracts[contractName].address : ""}
            size="180"
            level="H"
            includeMargin
            renderAs="svg"
            imageSettings={{ excavate: false }}
          />
        </div>
        <div>
          <Address
            address={readContracts ? readContracts[contractName].address : readContracts}
            ensProvider={mainnetProvider}
            blockExplorer={blockExplorer}
            fontSize={32}
          />
        </div>
      </div>
      <List
        bordered
        dataSource={executeTransactionEvents}
        renderItem={item => {
          return (
            <>
              <TransactionListItem
                item={item}
                mainnetProvider={mainnetProvider}
                localProvider={localProvider}
                blockExplorer={blockExplorer}
                price={price}
                readContracts={readContracts}
                contractName={contractName}
              />
            </>
          );
        }}
      />
      {/* <Events
        contracts={readContracts}
        contractName="MultiSig"
        eventName="Execute"
        localProvider={localProvider}
        mainnetProvider={mainnetProvider}
        startBlock={1}
      /> */}
    </div>
  );
}
