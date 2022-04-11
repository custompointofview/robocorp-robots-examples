*** Settings ***
Documentation     Template robot main suite.
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${PATH_SCREENSHOTS}    ${OUTPUT_DIR}${/}screenshots${/}
${PATH_PDFS}      ${OUTPUT_DIR}${/}pdfs${/}

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    Log    Starting execution...
    ${orders_url}=    Get URL from Vault
    IF    "${orders_url}" == ""
        ${orders_url}=    Get the URL for orders
    END
    Download orders file    ${orders_url}
    ${orders_table}=    Parse CSV file
    Open the intranet website
    FOR    ${row}    IN    @{orders_table}
        Log    ${row}
        Wait Until Keyword Succeeds    3x    0.5 sec    Close the question modal
        Fill the order form    ${row}
        ${screenshot}=    Preview the robot    ${row}[Order number]
        Wait Until Keyword Succeeds    3x    10 sec    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Wait Until Keyword Succeeds    3x    0.5 sec    Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Log out and close the browser

*** Keywords ***
Get URL from Vault
    ${secret}=    Get Secret    course_level2
    Log    ${secret}
    [Return]    ${secret}[orders_url]

Get the URL for orders
    Add heading    Input URL for orders CSV
    Add text input
    ...    name=url
    ...    label=url
    ...    placeholder=Enter URL here
    ${result}=    Run dialog
    [Return]    ${result.url}

Download orders file
    [Arguments]    ${url}
    Log    Starting download...
    Download    ${url}    overwrite=True
    Log    Done

Parse CSV file
    Log    Parsing CSV...
    ${orders_table}=    Read table from CSV    orders.csv
    Log    Done
    [Return]    ${orders_table}

Open the intranet website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the question modal
    Wait Until Element Is Visible    css:div.alert-buttons
    Click Button    OK

Fill the order form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    [Arguments]    ${name}
    Click Button    Preview
    Wait Until Page Contains Element    id:robot-preview-image
    Screenshot    robot-preview-image    ${PATH_SCREENSHOTS}${name}.png
    [Return]    ${PATH_SCREENSHOTS}${name}.png

Submit the order
    Click Button    order
    Wait Until Page Contains Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order}
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_results_html}    ${PATH_PDFS}${order}.pdf
    [Return]    ${PATH_PDFS}${order}.pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf

Go to order another robot
    Wait Until Page Contains Element    id:order-another
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${PATH_PDFS}    ${OUTPUT_DIR}${/}receipts.zip

Log out and close the browser
    Close Browser
