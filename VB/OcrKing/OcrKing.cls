VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "OcrKing"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'//////////////////////////////////////////////////////////////////////////////
'@@summary
'@@require
'@@reference
'@@license
'@@author
'@@create
'@@modify
'//////////////////////////////////////////////////////////////////////////////


'//////////////////////////////////////////////////////////////////////////////
'//
'//      ��������
'//
'//////////////////////////////////////////////////////////////////////////////


'------------------------------------------------------------------------------
'       �ӿڼ̳�
'------------------------------------------------------------------------------


'------------------------------------------------------------------------------
'       ���г���
'------------------------------------------------------------------------------


'------------------------------------------------------------------------------
'       ������������
'------------------------------------------------------------------------------


'------------------------------------------------------------------------------
'       ���б���
'------------------------------------------------------------------------------


'------------------------------------------------------------------------------
'       ����API
'------------------------------------------------------------------------------


'------------------------------------------------------------------------------
'       �¼�����
'------------------------------------------------------------------------------


'//////////////////////////////////////////////////////////////////////////////
'//
'//      ˽������
'//
'//////////////////////////////////////////////////////////////////////////////


'------------------------------------------------------------------------------
'       ˽�г���
'------------------------------------------------------------------------------


'------------------------------------------------------------------------------
'       ˽����������
'------------------------------------------------------------------------------


'------------------------------------------------------------------------------
'       ˽�б���
'------------------------------------------------------------------------------
Private mWinHttpReq As WinHttp.WinHttpRequest '����һ������
Private mList As CList
Private mKey As String

'------------------------------------------------------------------------------
'       ���Ա���
'------------------------------------------------------------------------------


'------------------------------------------------------------------------------
'       ˽��API
'------------------------------------------------------------------------------


'//////////////////////////////////////////////////////////////////////////////
'//
'//      ��
'//
'//////////////////////////////////////////////////////////////////////////////


'------------------------------------------------------------------------------
'       ��ʼ��
'------------------------------------------------------------------------------
Private Sub Class_Initialize()
  Set mWinHttpReq = New WinHttp.WinHttpRequest
  Set mList = New CList
End Sub


'------------------------------------------------------------------------------
'       ����
'------------------------------------------------------------------------------
Private Sub Class_Terminate()
  Set mWinHttpReq = Nothing
  Set mList = Nothing
End Sub


'//////////////////////////////////////////////////////////////////////////////
'//
'//      �¼�����
'//
'//////////////////////////////////////////////////////////////////////////////


'//////////////////////////////////////////////////////////////////////////////
'//
'//      ˽������
'//
'//////////////////////////////////////////////////////////////////////////////


'//////////////////////////////////////////////////////////////////////////////
'//
'//      ˽�з���
'//
'//////////////////////////////////////////////////////////////////////////////
Private Sub JoinBin(dest() As Byte, source() As Byte)
'�ϳ��ֽ�����
  Dim baseSize As Long, i As Long
  
  If UBound(dest) > 0 Then
    baseSize = UBound(dest) + 1
    ReDim Preserve dest(UBound(dest) + UBound(source) + 1)
  Else
    baseSize = 0
    ReDim dest(UBound(source))
  End If
  For i = 0 To UBound(source)
    dest(baseSize + i) = source(i)
  Next i
End Sub

Private Function BytesToBstr(strBody As Variant, ByVal CodeBase As String)
'����ת��("UTF-8"����"GB2312"����"GBK")
  Dim ObjStream
  Set ObjStream = CreateObject("Adodb.Stream")
  With ObjStream
    .Type = 1
    .Mode = 3
    .Open
    .Write strBody
    .position = 0
    .Type = 2
    .Charset = CodeBase
    BytesToBstr = .ReadText
    .Close
  End With
  Set ObjStream = Nothing
End Function

Private Function BinString(ByVal content As String) As Byte()
'��ȡ�ַ������ֽ�����
  Dim source() As Byte, i As Long, countUp As Long, dest() As Byte
  source = content
  countUp = 0
  
  If Len(content) = 0 Then
    Exit Function
  End If
  
  ReDim dest(UBound(source))
  
  For i = 0 To UBound(source)
    If source(i) <> 0 Then
      dest(countUp) = source(i)
      countUp = countUp + 1
    End If
  Next i
  
  ReDim Preserve dest(countUp - 1)
  BinString = dest
End Function

Private Function LoadData(ByVal FilePath As String) As Byte()
'�����ļ����ֽ�����
  Dim Bin() As Byte, FileLength As Long
  Open FilePath For Binary As #1                   '�Զ����Ʒ�ʽ���ļ�
    FileLength = LOF(1) ''��ȡ�ļ����ȡ��ô�С���ֽ�Ϊ��λ
    ReDim Bin(FileLength - 1)                       '����Ϊ��̬����������·���洢�ռ䡣
    Get #1, , Bin                                 '��һ���Ѵ򿪵Ĵ����ļ�����һ������֮�С�
  Close #1
  LoadData = Bin
End Function

Private Function mGetFileName(ByVal mFilePath As String) As String
'���ļ�·���л�ȡ�ļ���
  mFilePath = Replace(mFilePath, "\\", "\")
  mGetFileName = Mid(mFilePath, InStrRev(mFilePath, "\") + 1)
End Function

Private Function mGetCodeFromXml(ByVal xmlCode As String, value As String) As Boolean
  Dim xmlDom As New MSXML2.DOMDocument, xmlNode As IXMLDOMNode
  mGetCodeFromXml = False
  If Not xmlDom.loadXML(xmlCode) Then
    Debug.Print "XML��ʽ����"
    Exit Function
  End If
  Set xmlNode = xmlDom.selectSingleNode("//Results/ResultList/Item")
  If Not xmlNode Is Nothing Then
    If xmlNode.selectSingleNode("Status").Text = "true" Then
      value = xmlNode.selectSingleNode("Result").Text
      mGetCodeFromXml = True
      Exit Function
    End If
  End If
End Function
'//////////////////////////////////////////////////////////////////////////////
'//
'//      ��������
'//
'//////////////////////////////////////////////////////////////////////////////
Public Property Get Key() As String
  Key = mKey
End Property

Public Property Let Key(ByVal vNewValue As String)
  mKey = vNewValue
End Property

'//////////////////////////////////////////////////////////////////////////////
'//
'//      ���з���
'//
'//////////////////////////////////////////////////////////////////////////////

Public Function GetCodeFromFile(ByVal FilePath As String) As String
'��ȡ��֤��ͼƬ������
  Dim url As String, boundary As String
  Dim part1 As String, part3 As String, responseXml As String, code As String
  Dim pic() As Byte, bindata() As Byte

  If mKey = "" Then
    Err.Raise 10001, , "[SunSoft]δָ��Key�����û��Key������ϵhttp://www.ocrking.com���룡"
  End If
  
  url = "http://lab.ocrking.com/ok.html"
  boundary = "------------------------------831b7f6f6a2d"
  ReDim bindata(0)
  
  pic = LoadData(FilePath)

  With mList
    .Clear
    .Add boundary & vbCrLf
    .Add "Content-Disposition: form-data; name=""ocrfile""; filename=""" & mGetFileName(FilePath) & """" & vbCrLf
    .Add "Content-Type: application/octet-stream" & vbCrLf
    .Add "" & vbCrLf
    part1 = .Join("")

    .Clear
    .Add "" & vbCrLf
    .Add boundary & vbCrLf
    .Add "Content-Disposition: form-data; name=""service""" & vbCrLf
    .Add "" & vbCrLf
    .Add "OcrKingForCaptcha" & vbCrLf
    .Add boundary & vbCrLf
    .Add "Content-Disposition: form-data; name=""language""" & vbCrLf
    .Add "" & vbCrLf
    .Add "eng" & vbCrLf
    .Add boundary & vbCrLf
    .Add "Content-Disposition: form-data; name=""type""" & vbCrLf
    .Add "" & vbCrLf
    .Add "http://www.nopreprocess.com" & vbCrLf
    .Add boundary & vbCrLf
    .Add "Content-Disposition: form-data; name=""charset""" & vbCrLf
    .Add "" & vbCrLf
    .Add "7" & vbCrLf
    .Add boundary & vbCrLf
    .Add "Content-Disposition: form-data; name=""apiKey""" & vbCrLf
    .Add "" & vbCrLf
    .Add mKey & vbCrLf
    .Add boundary & "--" & vbCrLf
    .Add "" & vbCrLf
    .Add "" & vbCrLf
    .Add "" & vbCr
    part3 = .Join("")
  End With
  
  JoinBin bindata, BinString(part1)
  JoinBin bindata, pic
  JoinBin bindata, BinString(part3)
  
  mWinHttpReq.Open "POST", url, True
  mWinHttpReq.SetTimeouts 30000, 30000, 30000, 30000
  mWinHttpReq.SetRequestHeader "User-Agent", "Mozilla/5.0 (Windows NT 5.1; zh-CN; rv:1.9.1.3) Gecko/20100101 Firefox/8.0"
  mWinHttpReq.SetRequestHeader "Host", "lab.ocrking.com"
  mWinHttpReq.SetRequestHeader "Accept", "*/*"
  mWinHttpReq.SetRequestHeader "Content-Type", "multipart/form-data; boundary=" & Mid(boundary, 3)

  mWinHttpReq.Send bindata        '����
  mWinHttpReq.WaitForResponse  '�첽����
  responseXml = BytesToBstr(mWinHttpReq.ResponseBody, "UTF-8")
  If mGetCodeFromXml(responseXml, code) Then
    GetCodeFromFile = code
  Else
    GetCodeFromFile = ""
  End If
End Function
