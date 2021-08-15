# -------------------------------------------------------------------------------------------------
#  Copyright (C) 2015-2021 Nautech Systems Pty Ltd. All rights reserved.
#  https://nautechsystems.io
#
#  Licensed under the GNU Lesser General Public License Version 3.0 (the "License");
#  You may not use this file except in compliance with the License.
#  You may obtain a copy of the License at https://www.gnu.org/licenses/lgpl-3.0.en.html
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# -------------------------------------------------------------------------------------------------

import asyncio
import os

from betfairlightweight import APIClient

from nautilus_trader.adapters.betfair.data cimport BetfairDataClient
from nautilus_trader.adapters.betfair.execution cimport BetfairExecutionClient
from nautilus_trader.cache.cache cimport Cache
from nautilus_trader.common.clock cimport LiveClock
from nautilus_trader.common.logging cimport LiveLogger
from nautilus_trader.live.data_client cimport LiveDataClientFactory
from nautilus_trader.live.execution_client cimport LiveExecutionClientFactory
from nautilus_trader.model.currency cimport Currency
from nautilus_trader.model.identifiers cimport AccountId
from nautilus_trader.msgbus.bus cimport MessageBus

from nautilus_trader.adapters.betfair.common import BETFAIR_VENUE


cdef class BetfairLiveDataClientFactory(LiveDataClientFactory):
    @staticmethod
    def create(
        loop not None: asyncio.AbstractEventLoop,
        str name not None,
        dict config not None,
        MessageBus msgbus not None,
        Cache cache not None,
        LiveClock clock not None,
        LiveLogger logger not None,
        client_cls=None,
    ):
        """
        Create new Betfair clients.

        Parameters
        ----------
        loop : asyncio.AbstractEventLoop
            The event loop for the clients.
        name : str
            The client name.
        config : dict
            The configuration dictionary.
        msgbus : MessageBus
            The message bus for the clients.
        cache : Cache
            The cache for the clients.
        clock : LiveClock
            The clock for the clients.
        logger : LiveLogger
            The logger for the clients.
        client_cls : class, optional
            The class to call to return a new internal client.

        Returns
        -------
        BetfairDataClient

        """
        # Create client
        client = APIClient(
            username=os.getenv(config.get("username", ""), ""),
            password=os.getenv(config.get("password", ""), ""),
            app_key=os.getenv(config.get("app_key", ""), ""),
            certs=os.getenv(config.get("cert_dir", ""), ""),
            lightweight=True,
        )

        data_client = BetfairDataClient(
            loop=loop,
            client=client,
            msgbus=msgbus,
            cache=cache,
            clock=clock,
            logger=logger,
            market_filter=config.get("market_filter", {})
        )
        return data_client


cdef class BetfairLiveExecutionClientFactory(LiveExecutionClientFactory):
    """
    Provides data and execution clients for Betfair.
    """

    @staticmethod
    def create(
        loop not None: asyncio.AbstractEventLoop,
        str name not None,
        dict config not None,
        MessageBus msgbus not None,
        Cache cache not None,
        LiveClock clock not None,
        LiveLogger logger not None,
        client_cls=None,
    ):
        """
        Create new Betfair clients.

        Parameters
        ----------
        loop : asyncio.AbstractEventLoop
            The event loop for the clients.
        name : str
            The client name.
        config : dict
            The configuration dictionary.
        msgbus : MessageBus
            The message bus for the clients.
        cache : Cache
            The cache for the clients.
        clock : LiveClock
            The clock for the clients.
        logger : LiveLogger
            The logger for the clients.
        client_cls : class, optional
            The class to call to return a new internal client.

        Returns
        -------
        BetfairExecClient

        """
        # Create client
        client = APIClient(
            username=os.getenv(config.get("username", ""), ""),
            password=os.getenv(config.get("password", ""), ""),
            app_key=os.getenv(config.get("app_key", ""), ""),
            certs=os.getenv(config.get("cert_dir", ""), ""),
            lightweight=True,
        )

        # Get account ID env variable or set default
        account_id_env_var = os.getenv(config.get("account_id", ""), "001")

        # Set account ID
        account_id = AccountId(BETFAIR_VENUE.value, account_id_env_var)

        # Create client
        exec_client = BetfairExecutionClient(
            loop=loop,
            client=client,
            account_id=account_id,
            base_currency=Currency.from_str_c(config.get("base_currency")),
            msgbus=msgbus,
            cache=cache,
            clock=clock,
            logger=logger,
            market_filter=config.get("market_filter", {})
        )
        return exec_client
