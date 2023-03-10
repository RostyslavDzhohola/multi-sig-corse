import React, { useState } from "react";
import { Button, List } from "antd";

import { Address, Balance, Blockie, TransactionDetailsModal, Events } from "../components";
import { EllipsisOutlined } from "@ant-design/icons";
import { parseEther, formatEther } from "@ethersproject/units";

const TransactionListItem = function ({
  item,
  mainnetProvider,
  localProvider,
  blockExplorer,
  price,
  readContracts,
  contractName,
  children,
}) {
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [txnInfo, setTxnInfo] = useState(null);

  const showModal = () => {
    setIsModalVisible(true);
  };

  const handleOk = () => {
    setIsModalVisible(false);
  };

  const buildTxnTransferData = transaction => {
    return {
      functionFragment: {
        inputs: [],
        name: "Execute",
      },
      signature: "",
      args: [transaction.to],
      sighash: item.data,
    };
  };

  console.log("🔥🔥🔥🔥 item object is => ", item);
  let txnData;
  let data = "14de327f";
  try {
    txnData =
      item.data === "" || item.data === "0x" || item.data === "0x00"
        ? buildTxnTransferData(item)
        : readContracts[contractName].interface.parseTransaction(item);
    // : readContracts[contractName].interface.parseTransaction(item); // try item.data
  } catch (error) {
    console.log("ERROR when buildTxnTransferData ", error);
    console.log("Contract name is ", contractName, "---> and readContracts is ", readContracts);
    console.log("txnData is ", txnData);
  }
  return (
    <>
      <p>
        {" "}
        Event name --- {item.event} || Tx number {item.args.txId.toNumber()}{" "}
      </p>

      {/* <Events
        contracts={readContracts}
        contractName="MultiSig"
        eventName="Execute"
        localProvider={localProvider}
        mainnetProvider={mainnetProvider}
        startBlock={1}
      /> */}
      <TransactionDetailsModal
        visible={isModalVisible}
        txnInfo={txnData}
        handleOk={handleOk}
        mainnetProvider={mainnetProvider}
        price={price}
      />
      {txnData && (
        <List.Item key={item.hash} style={{ position: "relative" }}>
          <div
            style={{
              position: "absolute",
              top: 55,
              fontSize: 12,
              opacity: 0.5,
              display: "flex",
              flexDirection: "row",
              width: "90%",
              justifyContent: "space-between",
            }}
          >
            <p>
              <b>Event Name :&nbsp;</b>
              {txnData.functionFragment.name}&nbsp;
            </p>
            <p>
              <b>Addressed to :&nbsp;</b>
              {txnData.args[0]}
            </p>
          </div>
          {<b style={{ padding: 16 }}>{typeof item.nonce === "number" ? item.nonce : item.nonce.toNumber()}</b>}
          <span>
            <Blockie size={4} scale={8} address={item.hash} /> {item.hash.substr(0, 6)}
          </span>
          <Address address={item.to} ensProvider={mainnetProvider} blockExplorer={blockExplorer} fontSize={16} />
          <Balance
            balance={item.value ? item.value : parseEther("" + parseFloat(item.amount).toFixed(12))}
            dollarMultiplier={price}
          />
          <>{children}</>
          <Button onClick={showModal}>
            <EllipsisOutlined />
          </Button>
        </List.Item>
      )}
    </>
  );
};
export default TransactionListItem;
