-module(erlyopen).

-compile(export_all).
-include_lib("wx/include/wx.hrl").
 
start() ->
    State = make_window(),
    loop (State).
 
make_window() ->
    Server = wx:new(),
    Frame = wxFrame:new(Server, -1, "Run command", [{size,{550, 200}}]),
    Panel  = wxPanel:new(Frame,[]),

    wxFrame:createStatusBar(Frame),
    wxFrame:setStatusText(Frame, "Waiting for input"),


%% create widgets
    T1001 = wxTextCtrl:new(Panel, 1001,[{style, ?wxHSCROLL bor ?wxTE_PROCESS_ENTER}]),  %% ?wxTE_MULTILINE bor
    wxTextCtrl:setEditable(T1001, true),

    B101  = wxButton:new(Panel, 101, [{label, "&Help"}]),
    B102  = wxButton:new(Panel, ?wxID_EXIT, [{label, "&Cancle"}]), 
    B103  = wxButton:new(Panel, ?wxID_EXIT, [{label, "&Run"}]), 

    wxFrame:connect(B101, command_button_clicked, [{callback, fun(_, _) ->  io:format("Users clicked button~n",[]) end }]),  %%handle_event}]),
    wxFrame:connect(T1001, command_text_enter, [{callback, fun(A, _) ->
								   Rec = A#wx.event,
								   io:format("RUNNING\n",[]),
								   case Rec of
								       {_,_,Txt,_,_} -> try
											    run(Txt)
											catch
											    _ -> SB = wxFrame:getStatusBar(Frame),
												 wxStatusBar:pushStatusText(SB, "Error")
											end
								   end
							   end}]),

    wxFrame:connect(T1001, command_text_updated, [{callback, fun(A, _) ->
								     Rec = A#wx.event,
								     case Rec  of
									 {_,_,Txt,_,_} -> SB = wxFrame:getStatusBar(Frame),
											  try 
											      T = run("whatis " ++ Txt),
											      wxStatusBar:pushStatusText(SB, lib:nonl(T))
											  catch
											      _ -> wxStatusBar:pushStatusText(SB, Txt)
											  end
								     end
							     end}]),


    G = wxBoxSizer:new( ?wxVERTICAL),
    H = wxBoxSizer:new( ?wxHORIZONTAL),
    wxSizer:add(G, 0, 0,  [{flag, ?wxEXPAND bor ?wxALIGN_CENTRE bor ?wxSHAPED}] ),
    wxSizer:add(G, T1001, [{flag, ?wxEXPAND bor ?wxALIGN_CENTRE bor ?wxSHAPED}] ),

    wxSizer:add(H, B101,    [{flag, ?wxALIGN_RIGHT}]),
    wxSizer:add(H, B102,    [{flag, ?wxALIGN_RIGHT}]),
    wxSizer:add(H, B103,    [{flag, ?wxALIGN_RIGHT}]),
    wxSizer:add(G, H, [{flag,   ?wxEXPAND  }]),
    wxWindow:setSizer(Panel, G),

    wxFrame:show(Frame),
    io:format("ready\n",[]),
    {Frame, T1001, G}.

loop(State) ->  State,
    ok.

handle_event(#wx{}, State) ->
    io:format("Users clicked button~n",[]),
    {noreply, State};

handle_event(_, _) ->
    io:format("Users clicked button~n",[]),
    {noreply, ""}.




run(Cmd) ->
	run(Cmd, 5000).

run(Cmd, Timeout) ->
	Port = erlang:open_port({spawn, Cmd},[exit_status]),
	loop(Port,[], Timeout).

loop(Port, Data, Timeout) ->
	receive
		{Port, {data, NewData}} -> loop(Port, Data++NewData, Timeout);
		{Port, {exit_status, 0}} -> Data;
		{Port, {exit_status, S}} -> throw({commandfailed, S})
	after Timeout ->
		throw(timeout)
	end.

test() ->
	shouldReturnCommandResult(),
	shouldThrowAfterTimeout(),
	shouldThrowIfCmdFailed(),
	{ok, "Tests PASSED"}.

shouldReturnCommandResult() ->
	"Hello\n" = run("echo Hello").

shouldThrowAfterTimeout()->
	timeout = (catch run("sleep 10", 20)).

shouldThrowIfCmdFailed()->
		{commandfailed, _} = (catch run("wrongcommand")),
		{commandfailed, _} = (catch run("ls nonexistingfile")).