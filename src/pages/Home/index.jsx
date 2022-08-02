import React, { useEffect, useState } from "react"
import { Header } from "../../components/Header"
import { First } from "./First"
import CustomizedSnackbars from "../../components/SnackBar"
import styles from './Home.module.scss'
import { useSelector } from "react-redux"
import { onConnect } from "../../utils/WalletConnect"
import { useDispatch } from "react-redux"
import * as utils from '@0x/protocol-utils'
import { MetamaskSubprovider } from '@0x/subproviders'
import contractAddress from '@0x/contract-addresses'
import qs from 'qs'

const Home = () => {
    const wallet = useSelector((state) => state.wallet)
    const dispatch = useDispatch()
    const [notice, setNotice] = useState({ type: "", msg: "", show: false })

    useEffect(() => {
        const init = async () => {
            try {
                const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";
                const getFutureExpiryInSeconds = () =>
                    Math.floor(Date.now() / 1000 + 3000).toString();
                const order = new utils.LimitOrder({
                    makerToken: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
                    takerToken: "0xe41d2489571d322189246dafa5ebde1f4699f498",
                    makerAmount: new BigNumber(sellAmt).times(10 ** sellCur.token.decimals),
                    takerAmount: new BigNumber(buyAmt).times(10 ** buyCur.token.decimals),
                    maker: account,
                    sender: NULL_ADDRESS,
                    expiry: new BigNumber(getFutureExpiryInSeconds()),
                    salt: new BigNumber(Date.now().toString()),
                    chainId,
                    verifyingContract: "0xdef1c0ded9bec7f1a1670819833240f027b25eff",
                    takerTokenFeeAmount: new BigNumber("0"),
                    feeRecipient: NULL_ADDRESS
                });
                const _provider = new MetamaskSubprovider(window.ethereum)
                const signature = await order.getSignatureWithProviderAsync(
                    _provider,
                    utils.SignatureType.EIP712
                );
                const signedOrder = { ...order, signature }
                console.log("Sign Success:", JSON.stringify(signedOrder))
                const resp = await fetch("https://bsc.api.0x.org/orderbook/v1/order", {
                    method: "POST",
                    body: JSON.stringify(signedOrder),
                    headers: {
                        "Content-Type": "application/json"
                    }
                });
                if (resp.status === 200) {
                    alert("Successfully posted order to SRA");
                } else {
                    const body = await resp.json();
                    alert(
                        `ERROR(status code ${resp.status}): ${JSON.stringify(body, undefined, 2)}`
                    )
                }
            } catch (err) {
                console.log("Sign Failed:", err)
            }
        }

        init()
    }, [wallet])

    return (
        <div className={styles.home}>
            <CustomizedSnackbars notice={notice} setNotice={setNotice} />
            <Header account={wallet.account}
                chainId={wallet.chainId}
                setNotice={setNotice}
                handleClick={() => onConnect(dispatch)} />
            <First web3={wallet.web3}
                account={wallet.account}
                chainId={wallet.chainId}
                setNotice={setNotice} />
        </div>
    )
}

export default Home;