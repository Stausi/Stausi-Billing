import React, { useEffect, useRef, useState } from 'react';
import './CheckmarkButton.css';

import "./App.css";
const devMode = !window.invokeNative;

const App = () => {
    const [isDarkMode, setDarkMode] = useState(true);
    const [billings, setBillings] = useState([]);

    const appDiv = useRef(null);
    const { fetchNui, getSettings, onSettingsChange } = window;

    async function handleButtonClick(id) {
        const updatedBillings = billings.map(billing => {
            if (billing.id === id) {
                return { ...billing, isAnimating: true };
            }
            return billing;
        });
        
        setBillings(updatedBillings);
        await fetchNui("payBill", { id: id });
    };

    useEffect(() => {
        if (devMode) {
            document.getElementsByTagName("html")[0].style.visibility = "visible";
            document.getElementsByTagName("body")[0].style.visibility = "visible";
            return;
        }

        const setupSettings = async () => {
            if (devMode) return;

            getSettings().then((settings) => setDarkMode(settings.display.theme === "dark"));
            onSettingsChange((settings) => setDarkMode(settings.display.theme === "dark"));
        };

        const setupBillings = async () => {
            if (devMode) return;

            let newBillings = await fetchNui("setupApp", {});
            setBillings(newBillings);
        }

        setupSettings();
        setupBillings();

        window.addEventListener("message", async (event) => {
            switch (event.data.action) {
                case "refreshBillings":
                    setBillings(event.data.billings);
                    break;
                default:
                    break;
            }
        });

        return () => {
            setBillings([]);
        }
    }, [fetchNui, getSettings, onSettingsChange]);

    return (
        <AppProvider>
        <div className={`app ${isDarkMode ? "dark" : "light"}`} ref={appDiv}>
            <div className={`app-content`}>
                <h1 className="headline">Faktura/Bøder</h1>
                <div className={`player-billings`}>
                    {billings.length === 0 ? (
                        <p className="no-bills">Du har ingen Faktura/Bøder</p>
                    ) : (
                        billings.map((billing, index) => (
                            <div key={index} className="billing-container">
                                <div className="container-header">
                                    <h1>{ billing.label }</h1>
                                    <h1>{ billing.amount }</h1>
                                    <div className={`checkmark-wrapper ${billing.isAnimating ? 'checkmarked' : ''}`} onClick={() => handleButtonClick(billing.id)}>
                                        <span className={`checkmark ${billing.isAnimating ? 'animate-checkmark' : ''}`}></span>
                                    </div>
                                </div>
                            </div>
                        ))
                    )}
                </div>
            </div>
        </div>
    </AppProvider>
    );
};

const AppProvider = ({ children }) => {
    if (devMode) {
        return <div className='dev-wrapper'>{children}</div>;
    } else return children;
};

export default App;
