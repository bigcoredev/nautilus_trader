# -------------------------------------------------------------------------------------------------
#  Copyright (C) 2015-2020 Nautech Systems Pty Ltd. All rights reserved.
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

from cpython.datetime cimport datetime
import os

import ccxt

from nautilus_trader.adapters.binance.providers import BinanceInstrumentProvider
from nautilus_trader.common.clock cimport LiveClock
from nautilus_trader.common.logging cimport Logger
from nautilus_trader.core.correctness cimport Condition
from nautilus_trader.core.constants cimport *  # str constants only
from nautilus_trader.core.datetime cimport from_posix_ms
from nautilus_trader.core.datetime cimport to_posix_ms
from nautilus_trader.core.uuid cimport UUID
from nautilus_trader.live.data cimport LiveDataClient
from nautilus_trader.live.data cimport LiveDataEngine
from nautilus_trader.model.c_enums.order_side cimport OrderSide
from nautilus_trader.model.c_enums.price_type cimport PriceType
from nautilus_trader.model.c_enums.price_type cimport PriceTypeParser
from nautilus_trader.model.bar cimport Bar
from nautilus_trader.model.bar cimport BarType
from nautilus_trader.model.identifiers cimport Symbol
from nautilus_trader.model.identifiers cimport Venue
from nautilus_trader.model.identifiers cimport TradeMatchId
from nautilus_trader.model.instrument cimport Instrument
from nautilus_trader.model.objects cimport Price
from nautilus_trader.model.objects cimport Quantity
from nautilus_trader.model.tick cimport TradeTick


cdef class BinanceDataClient(LiveDataClient):
    """
    Provides a data client for the `Binance` exchange.
    """

    def __init__(
        self,
        dict credentials,
        LiveDataEngine engine,
        LiveClock clock,
        Logger logger,
    ):
        """
        Initialize a new instance of the `BinanceDataClient` class.

        Parameters
        ----------
        credentials : dict[str, str]
            The API credentials for the client.
        engine : LiveDataEngine
            The live data engine for the client.
        clock : LiveClock
            The clock for the client.
        logger : Logger
            The logger for the client.

        """
        Condition.not_none(credentials, "credentials")
        super().__init__(
            Venue("BINANCE"),
            engine,
            clock,
            logger,
        )

        cdef dict config = {
            "apiKey": os.getenv(credentials.get("api_key", "")),
            "secret": os.getenv(credentials.get("api_secret", "")),
            "timeout": 10000,
            "enableRateLimit": True,
        }

        self._is_connected = False
        self._config = config
        self._client = ccxt.binance(config=config)
        self._instrument_provider = BinanceInstrumentProvider(
            client=self._client,
            load_all=False,
        )

        self._subscribed_instruments = set()

        # Schedule subscribed instruments update in one hour
        self._loop.call_later(60 * 60, self._subscribed_instruments_update)

    def __repr__(self) -> str:
        return f"{type(self).__name__}"

    cpdef bint is_connected(self) except *:
        """
        Return a value indicating whether the client is connected.

        Returns
        -------
        bool
            True if connected, else False.

        """
        return self._is_connected

    cpdef void connect(self) except *:
        """
        Connect the client.
        """
        self._log.info("Connecting...")

        # TODO: Connect websocket here

        self._is_connected = True
        self._log.info("Connected.")

    cpdef void disconnect(self) except *:
        """
        Disconnect the client.
        """
        self._log.info("Disconnecting...")

        self._is_connected = False

        self._log.info("Disconnected.")

    cpdef void reset(self) except *:
        """
        Reset the client.
        """
        self._client = ccxt.binance(config=self._config)
        self._instrument_provider = BinanceInstrumentProvider(
            client=self._client,
            load_all=False,
        )

        self._subscribed_instruments = set()

        # Schedule subscribed instruments update in one hour
        self._loop.call_later(60 * 60, self._subscribed_instruments_update)

    cpdef void dispose(self) except *:
        """
        Dispose the client.
        """
        pass  # Nothing to dispose yet

# -- SUBSCRIPTIONS ---------------------------------------------------------------------------------

    cpdef void subscribe_instrument(self, Symbol symbol) except *:
        """
        Subscribe to `Instrument` data for the given symbol.

        Parameters
        ----------
        symbol : Instrument
            The instrument symbol to subscribe to.

        """
        Condition.not_none(symbol, "symbol")

        self._subscribed_instruments.add(symbol)

    cpdef void subscribe_quote_ticks(self, Symbol symbol) except *:
        """
        Subscribe to `QuoteTick` data for the given symbol.

        Parameters
        ----------
        symbol : Symbol
            The tick symbol to subscribe to.

        """
        Condition.not_none(symbol, "symbol")

        # TODO: Implement

    cpdef void subscribe_trade_ticks(self, Symbol symbol) except *:
        """
        Subscribe to `TradeTick` data for the given symbol.

        Parameters
        ----------
        symbol : Symbol
            The tick symbol to subscribe to.

        """
        Condition.not_none(symbol, "symbol")

        # TODO: Implement

    cpdef void subscribe_bars(self, BarType bar_type) except *:
        """
        Subscribe to `Bar` data for the given bar type.

        Parameters
        ----------
        bar_type : BarType
            The bar type to subscribe to.

        """
        Condition.not_none(bar_type, "bar_type")

        # TODO: Implement

    cpdef void unsubscribe_instrument(self, Symbol symbol) except *:
        """
        Unsubscribe from `Instrument` data for the given symbol.

        Parameters
        ----------
        symbol : Symbol
            The instrument symbol to unsubscribe from.

        """
        Condition.not_none(symbol, "symbol")

        self._subscribed_instruments.discard(symbol)

    cpdef void unsubscribe_quote_ticks(self, Symbol symbol) except *:
        """
        Unsubscribe from `QuoteTick` data for the given symbol.

        Parameters
        ----------
        symbol : Symbol
            The tick symbol to unsubscribe from.

        """
        Condition.not_none(symbol, "symbol")

        # TODO: Implement

    cpdef void unsubscribe_trade_ticks(self, Symbol symbol) except *:
        """
        Unsubscribe from `TradeTick` data for the given symbol.

        Parameters
        ----------
        symbol : Symbol
            The tick symbol to unsubscribe from.

        """
        Condition.not_none(symbol, "symbol")

        # TODO: Implement

    cpdef void unsubscribe_bars(self, BarType bar_type) except *:
        """
        Unsubscribe from `Bar` data for the given bar type.

        Parameters
        ----------
        bar_type : BarType
            The bar type to unsubscribe from.

        """
        Condition.not_none(bar_type, "bar_type")

        # TODO: Implement

# -- REQUESTS --------------------------------------------------------------------------------------

    cpdef void request_instrument(self, Symbol symbol, UUID correlation_id) except *:
        """
        Request the instrument for the given symbol.

        Parameters
        ----------
        symbol : Symbol
            The symbol for the request.
        correlation_id : UUID
            The correlation identifier for the request.

        """
        Condition.not_none(symbol, "symbol")
        Condition.not_none(correlation_id, "correlation_id")

        self._loop.run_in_executor(None, self._request_instrument, symbol, correlation_id)

    cpdef void request_instruments(self, UUID correlation_id) except *:
        """
        Request all instruments.

        Parameters
        ----------
        correlation_id : UUID
            The correlation identifier for the request.

        """
        Condition.not_none(correlation_id, "correlation_id")

        self._loop.run_in_executor(None, self._request_instruments, correlation_id)

    cpdef void request_quote_ticks(
        self,
        Symbol symbol,
        datetime from_datetime,
        datetime to_datetime,
        int limit,
        UUID correlation_id,
    ) except *:
        """
        Request historical quote ticks for the given parameters.

        Parameters
        ----------
        symbol : Symbol
            The tick symbol for the request.
        from_datetime : datetime, optional
            The specified from datetime for the data
        to_datetime : datetime, optional
            The specified to datetime for the data. If None then will default
            to the current datetime.
        limit : int
            The limit for the number of returned ticks.
        correlation_id : UUID
            The correlation identifier for the request.

        """
        Condition.not_none(symbol, "symbol")
        Condition.not_negative_int(limit, "limit")
        Condition.not_none(correlation_id, "correlation_id")

        self._log.error("`request_quote_ticks` was called when not supported "
                        "by the exchange, use trade ticks.")

    cpdef void request_trade_ticks(
        self,
        Symbol symbol,
        datetime from_datetime,
        datetime to_datetime,
        int limit,
        UUID correlation_id,
    ) except *:
        """
        Request historical trade ticks for the given parameters.

        Parameters
        ----------
        symbol : Symbol
            The tick symbol for the request.
        from_datetime : datetime, optional
            The specified from datetime for the data
        to_datetime : datetime, optional
            The specified to datetime for the data. If None then will default
            to the current datetime.
        limit : int
            The limit for the number of returned ticks.
        correlation_id : UUID
            The correlation identifier for the request.

        """
        Condition.not_none(symbol, "symbol")
        Condition.not_negative_int(limit, "limit")
        Condition.not_none(correlation_id, "correlation_id")

        if to_datetime is not None:
            self._log.warning(f"`request_trade_ticks` was called with a `to_datetime` "
                              f"argument of {to_datetime} when not supported by the exchange "
                              f"(will use `limit` of {limit}).")

        self._loop.run_in_executor(
            None,
            self._request_trade_ticks,
            symbol,
            from_datetime,
            to_datetime,
            limit,
            correlation_id,
        )

    cpdef void request_bars(
        self,
        BarType bar_type,
        datetime from_datetime,
        datetime to_datetime,
        int limit,
        UUID correlation_id,
    ) except *:
        """
        Request historical bars for the given parameters.

        Parameters
        ----------
        bar_type : BarType
            The bar type for the request.
        from_datetime : datetime, optional
            The specified from datetime for the data
        to_datetime : datetime, optional
            The specified to datetime for the data. If None then will default
            to the current datetime.
        limit : int
            The limit for the number of returned bars.
        correlation_id : UUID
            The correlation identifier for the request.

        """
        Condition.not_none(bar_type, "bar_type")
        Condition.not_negative_int(limit, "limit")
        Condition.not_none(correlation_id, "correlation_id")

        if bar_type.spec.price_type != PriceType.LAST:
            self._log.error(f"`request_bars` was called with a `price_type` argument "
                            f"of `PriceType.{PriceTypeParser.to_str(bar_type.spec.price_type)}` "
                            f"when not supported by the exchange (must be LAST).")
            return

        if to_datetime is not None:
            self._log.warning(f"`request_bars` was called with a `to_datetime` "
                              f"argument of `{to_datetime}` when not supported by the exchange "
                              f"(will use `limit` of {limit}).")

        self._loop.run_in_executor(
            None,
            self._request_bars,
            bar_type,
            from_datetime,
            to_datetime,
            limit,
            correlation_id,
        )

# -- INTERNAL --------------------------------------------------------------------------------------

    cpdef TradeTick _parse_trade_tick(self, Instrument instrument, dict trade):
        return TradeTick(
            symbol=instrument.symbol,
            price=Price(trade['price'], instrument.price_precision),
            size=Quantity(trade['amount'], instrument.size_precision),
            side=OrderSide.BUY if trade["side"] == "buy" else OrderSide.SELL,
            match_id=TradeMatchId(trade["id"]),
            timestamp=from_posix_ms(trade["timestamp"]),
        )

    cpdef Bar _parse_bar(self, Instrument instrument, list values):
        return Bar(
            open_price=Price(values[1], instrument.price_precision),
            high_price=Price(values[2], instrument.price_precision),
            low_price=Price(values[3], instrument.price_precision),
            close_price=Price(values[4], instrument.price_precision),
            volume=Quantity(values[5], instrument.size_precision),
            timestamp=from_posix_ms(values[0]),
        )

    def _request_instrument(self, Symbol symbol, UUID correlation_id):
        self._instrument_provider.load_all()
        self._loop.call_soon_threadsafe(self._send_instrument_with_correlation, symbol, correlation_id)

    def _request_instruments(self, UUID correlation_id):
        self._instrument_provider.load_all()
        self._loop.call_soon_threadsafe(self._send_instruments, correlation_id)

    def _send_instrument_with_correlation(self, Symbol symbol, UUID correlation_id):
        cdef Instrument instrument = self._instrument_provider.get_all().get(symbol)
        if instrument is not None:
            self._handle_instruments([instrument], correlation_id)
        else:
            self._log.error(f"Could not find instrument {symbol.code}.")

    def _send_instrument(self, Symbol symbol):
        cdef Instrument instrument = self._instrument_provider.get_all().get(symbol)
        if instrument is not None:
            self._handle_instrument(instrument)
        else:
            self._log.error(f"Could not find instrument {symbol.code}.")

    def _send_instruments(self, UUID correlation_id):
        cdef list instruments = list(self._instrument_provider.get_all().values())
        self._handle_instruments(instruments, correlation_id)

        self._log.info(f"Updated {len(instruments)} instruments.")
        self.initialized = True

    def _send_trade_ticks(self, Symbol symbol, list ticks, UUID correlation_id):
        self._handle_trade_ticks(symbol, ticks, correlation_id)

    def _send_bars(self, BarType bar_type, list bars, UUID correlation_id):
        self._handle_bars(bar_type, bars, correlation_id)

    def _subscribed_instruments_update(self):
        self._loop.run_in_executor(None, self._subscribed_instruments_load_and_send)

    def _subscribed_instruments_load_and_send(self):
        self._instrument_provider.load_all()

        cdef Symbol symbol
        for symbol in self._subscribed_instruments:
            self._loop.call_soon_threadsafe(self._send_instrument, symbol)

        # Reschedule subscribed instruments update in one hour
        self._loop.call_later(60 * 60, self._subscribed_instruments_update)

    def _request_trade_ticks(
        self,
        Symbol symbol,
        datetime from_datetime,
        datetime to_datetime,
        int limit,
        UUID correlation_id,
    ):
        cdef Instrument instrument = self._instrument_provider.get(symbol)
        if instrument is None:
            self._log.error(f"Cannot request trade ticks (no instrument for {symbol}).")
            return

        cdef list trades
        try:
            trades = self._client.fetch_trades(
                symbol=symbol.code,
                since=to_posix_ms(from_datetime) if from_datetime is not None else None,
                limit=limit,
            )
        except Exception as ex:
            self._log.error(str(ex))
            return

        if len(trades) == 0:
            self._log.error("No data returned from fetch_trades.")
            return

        cdef list ticks = []  # type: list[TradeTick]
        cdef dict trade       # type: dict[str, object]
        for trade in trades:
            ticks.append(self._parse_trade_tick(instrument, trade))

        self._loop.call_soon_threadsafe(
            self._send_trade_ticks,
            symbol,
            ticks,
            correlation_id,
        )

    def _request_bars(
        self,
        BarType bar_type,
        datetime from_datetime,
        datetime to_datetime,
        int limit,
        UUID correlation_id,
    ):
        cdef Instrument instrument = self._instrument_provider.get(bar_type.symbol)
        if instrument is None:
            self._log.error(f"Cannot request bars (no instrument for {bar_type.symbol}).")
            return

        cdef list data
        try:
            data = self._client.fetch_ohlcv(
                symbol=bar_type.symbol.code,
                since=to_posix_ms(from_datetime) if from_datetime is not None else None,
                limit=limit,
            )
        except Exception as ex:
            self._log.error(str(ex))
            return

        if len(data) == 0:
            self._log.error(f"No data returned for {bar_type}.")
            return

        cdef list bars = []  # type: list[Bar]
        cdef list values     # type: list[object]
        for values in data[:-1]:
            bars.append(self._parse_bar(instrument, values))

        self._loop.call_soon_threadsafe(
            self._send_bars,
            bar_type,
            bars,
            correlation_id,
        )
