﻿using System;
using System.Data;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Xml.Linq;
using System.Text;
using iTextSharp.text;
using System.Collections.Generic;
using System.IO;
using iTextSharp.text.pdf;
using NIH.CMMS.Inventory.BOL.People;
using NIH.CMMS.Inventory.BOL.Common;


namespace NIH.CMMS.Inventory.Web
{
    /// <summary>
    /// Summary description for Utils
    /// </summary>
    public static class Utils
    {
        public static List<Cell> cells = new List<Cell>();
        private static string[] AllowedExtensions = new string[]
            {
                ".DOC",
                ".DOCX",
                ".WPD",
                ".XLS",
                ".XLSX",
                ".PDF",
                ".JPG",
                ".DOC",
                ".GIF",
                ".PNG",
                ".VSD",
                ".PPT",
                ".PPTX",
                ".TXT"
            }
            ;



        #region "Report functions"
        public static void ExportToExcel(string fileName, GridView gv, string title, Dictionary<string, string> args)
        {
            gv.GridLines = GridLines.Both;

            using (StringWriter sw = new StringWriter())
            {
                using (HtmlTextWriter htw = new HtmlTextWriter(sw))
                {
                    //  Create a table to contain the grid
                    System.Web.UI.WebControls.Table table = new System.Web.UI.WebControls.Table();

                    //  include the gridline settings
                    table.GridLines = gv.GridLines;

                    int colCount = 0;
                    for (int i = 0; i < gv.Columns.Count; i++)
                    {
                        DataControlField dcf = gv.Columns[i];
                        if (!dcf.Visible)
                        {
                            gv.HeaderRow.Cells.RemoveAt(gv.Columns.IndexOf(dcf));
                            gv.FooterRow.Cells.RemoveAt(gv.Columns.IndexOf(dcf));
                            foreach (GridViewRow dr in gv.Rows)
                            {
                                dr.Cells.RemoveAt(gv.Columns.IndexOf(dcf));
                            }
                            gv.Columns.Remove(dcf);
                            i--;
                        }
                        else colCount++;
                    }



                    int infoRowsCount = 0;
                    if (args != null && args.Count > 0)
                    {
                        table.Rows.Add(new TableRow());
                        for (int cc = 0; cc < colCount; cc++) table.Rows[0].Cells.AddAt(cc, new TableCell());
                        infoRowsCount++;

                        if (!String.IsNullOrEmpty(title))
                        {
                            table.Rows.Add(new TableRow());
                            for (int cc = 0; cc < colCount; cc++) table.Rows[1].Cells.AddAt(cc, new TableCell());
                            table.Rows[1].Cells[0].Text = title;
                            infoRowsCount++;

                            table.Rows.Add(new TableRow());
                            for (int cc = 0; cc < colCount; cc++) table.Rows[2].Cells.AddAt(cc, new TableCell());
                            infoRowsCount++;
                        }

                        foreach (string arg in args.Keys)
                        {
                            table.Rows.Add(new TableRow());
                            for (int cc = 0; cc < colCount; cc++) table.Rows[3].Cells.AddAt(cc, new TableCell());
                            table.Rows[3].Cells[0].Text = arg;
                            table.Rows[3].Cells[1].Text = args[arg].ToString();
                            infoRowsCount++;
                        }

                        table.Rows.Add(new TableRow());
                        for (int cc = 0; cc < colCount; cc++) table.Rows[4].Cells.AddAt(cc, new TableCell());
                        infoRowsCount++;
                    }


                    //  add the header row to the table
                    TableRow trHeader = null;
                    if (gv.HeaderRow != null)
                    {
                        PrepareControlForExport(gv.HeaderRow);
                        table.Rows.Add(gv.HeaderRow);
                        trHeader = table.Rows[infoRowsCount];
                    }

                    //  add each of the data rows to the table
                    foreach (GridViewRow row in gv.Rows)
                    {
                        PrepareControlForExport(row);
                        table.Rows.Add(row);
                    }

                    //  add the footer row to the table
                    TableRow trFooter = null;
                    if (gv.FooterRow != null)
                    {
                        PrepareControlForExport(gv.FooterRow);
                        table.Rows.Add(gv.FooterRow);
                        trFooter = table.Rows[table.Rows.Count - 1];
                    }

                    List<int> columnsToRemove = new List<int>();
                    foreach (TableRow row in table.Rows)
                    {
                        if (table.Rows.GetRowIndex(row) < infoRowsCount) continue;
                        if (row == trHeader || row == trFooter) continue;

                        for (int r = 0; r < row.Cells.Count; r++)
                        {
                            LiteralControl ltlCell = null;
                            foreach (Control ctl in row.Cells[r].Controls)
                            {
                                if (ctl is LiteralControl &&
                                    (ctl as LiteralControl).Text.Trim().StartsWith("<b>"))
                                    ltlCell = ctl as LiteralControl;
                            }

                            if (ltlCell != null)
                            {
                                if (!columnsToRemove.Contains(r)) columnsToRemove.Add(r);

                                string[] newCols =
                                    ltlCell.Text.Replace("<br />", "~").Replace("<br/>", "~").Split('~');

                                for (int r2 = 0; r2 < newCols.Length; r2++)
                                {
                                    if (String.IsNullOrEmpty(newCols[r2])) continue;

                                    string newCol = newCols[r2];
                                    string heading = newCol.Substring(0, newCol.IndexOf("</b>") + 4).Replace(":", "").Trim();
                                    string content = newCol.Substring(newCol.IndexOf("</b>") + 4).Trim();

                                    if (String.IsNullOrEmpty(heading)) continue;

                                    int headerIndex = -1;
                                    foreach (TableCell tmp in trHeader.Cells)
                                    {
                                        foreach (Control ctl in tmp.Controls)
                                        {
                                            if (ctl is LiteralControl &&
                                                (ctl as LiteralControl).Text.Equals(heading))
                                                headerIndex = trHeader.Cells.GetCellIndex(tmp);
                                        }
                                    }

                                    if (headerIndex == -1)
                                    {
                                        TableCell newHeader = new TableCell();
                                        newHeader.Controls.Add(new LiteralControl(heading));
                                        trHeader.Cells.Add(newHeader);
                                        headerIndex = trHeader.Cells.GetCellIndex(newHeader);

                                        for (int rc = 0; rc < table.Rows.Count; rc++)
                                        {
                                            TableRow testRow = table.Rows[rc];
                                            if (table.Rows.GetRowIndex(row) < infoRowsCount) continue;
                                            if (testRow == trHeader || testRow == trFooter) continue;
                                            if (testRow.Cells.Count < headerIndex)
                                            {
                                                for (int i = testRow.Cells.Count; i < headerIndex; i++)
                                                {
                                                    testRow.Cells.AddAt(i, new TableCell());
                                                }
                                            }
                                            testRow.Cells.AddAt(headerIndex, new TableCell());
                                        }

                                        TableCell newFooter = new TableCell();
                                        newFooter.Controls.Add(new LiteralControl(string.Empty));
                                        trFooter.Cells.AddAt(headerIndex, newFooter);
                                    }

                                    row.Cells[headerIndex].Controls.Clear();
                                    row.Cells[headerIndex].Controls.Add(new LiteralControl(content));

                                }
                            }
                        }
                    }
                    foreach (int idx in columnsToRemove)
                    {
                        foreach (TableRow row in table.Rows)
                        {
                            if (row.Cells.Count >= idx) row.Cells.RemoveAt(idx);
                        }
                    }

                    try
                    {
                        //  render the table into the htmlwriter
                        table.RenderControl(htw);

                        //  render the htmlwriter into the response
                        HttpContext.Current.Response.Clear();
                        HttpContext.Current.Response.AddHeader("content-disposition", string.Format("attachment; filename={0}", fileName + ".xls"));
                        HttpContext.Current.Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                        HttpContext.Current.Response.Write(sw.ToString());
                        HttpContext.Current.Response.Charset = "";
                        HttpContext.Current.Response.Flush();



                        //    HttpContext.Current.Response.Clear();
                        //    HttpContext.Current.Response.Buffer = true;
                        //    HttpContext.Current.Response.Charset = "";
                        //    HttpContext.Current.Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                        //    HttpContext.Current.Response.AddHeader("content-disposition", "attachment;filename=GridView.xlsx");
                        //HttpContext.Current.Response.Write(sw.ToString());
                        //HttpContext.Current.Response.Flush();
                        //        HttpContext.Current.Response.End();


                    }
                    catch (Exception ex)
                    {
                        throw ex;
                    }
                    finally
                    {
                        HttpContext.Current.Response.End();
                    }
                }
            }
        }

        #region private static void PrepareControlForExport(Control control)
        private static void PrepareControlForExport(Control control)
        {
            for (int i = 0; i < control.Controls.Count; i++)
            {
                bool recurse = true;
                Control current = control.Controls[i];
                if (current.GetType().ToString().Equals("System.Web.UI.WebControls.DataControlLinkButton"))
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as LinkButton).Text));
                }
                else if (current is LinkButton)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as LinkButton).Text));
                }
                else if (current is ImageButton)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as ImageButton).AlternateText));
                }
                else if (current is HyperLink)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as HyperLink).Text));
                }
                else if (current is DropDownList)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as DropDownList).SelectedItem.Text));
                }
                else if (current is CheckBox)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as CheckBox).Checked ? "True" : "False"));
                }
                else if (current is Label)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as Label).Text));
                }
                else if (current is System.Web.UI.WebControls.Literal)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as Literal).Text));
                }
                else if (current is System.Web.UI.WebControls.TableCell)
                {
                    int idx = (control as GridViewRow).Cells.GetCellIndex((current as TableCell));
                    GridView gv = (GridView)(control as GridViewRow).NamingContainer;

                    if (gv.Columns[idx].Visible)
                    {
                        if (!String.IsNullOrEmpty((current as TableCell).Text))
                        {
                            recurse = true;
                            control.Controls.Remove(current);
                            TableCell tc = new TableCell();
                            Literal lit = new Literal();
                            lit.Text = (current as TableCell).Text;
                            tc.Controls.Add(lit);
                            control.Controls.AddAt(idx, tc);
                            current = tc;
                        }
                    }
                    else
                    {
                        recurse = false;
                        control.Controls.Remove(current);
                    }
                }

                if (recurse && current.HasControls())
                {
                    PrepareControlForExport(current);
                }
            }
        }
        #endregion

        #region public static void ExportToPDF(string fileName, GridView gv)
        public static void ExportToPDF(string fileName, GridView gv)
        {
            ExportToPDF(fileName, gv, null, null);
        }
        public static void ExportToPDF(string fileName, GridView gv, string title, Dictionary<string, string> args)
        {

            // initialize cells;
            cells.Clear();
            Document doc = new Document(PageSize.LEGAL.Rotate(), 0, 0, 15, 15);
            StringBuilder strData = new StringBuilder(string.Empty);
            try
            {
                StringWriter sw = new StringWriter();
                sw.WriteLine(Environment.NewLine);
                sw.WriteLine(Environment.NewLine);
                sw.WriteLine(Environment.NewLine);
                sw.WriteLine(Environment.NewLine);
                HtmlTextWriter htw = new HtmlTextWriter(sw);

                int colCount = 0;
                for (int i = 0; i < gv.Columns.Count; i++)
                {
                    DataControlField dcf = gv.Columns[i];
                    if (!dcf.Visible)
                    {
                        gv.HeaderRow.Cells.RemoveAt(gv.Columns.IndexOf(dcf));
                        gv.FooterRow.Cells.RemoveAt(gv.Columns.IndexOf(dcf));
                        foreach (GridViewRow dr in gv.Rows)
                        {
                            dr.Cells.RemoveAt(gv.Columns.IndexOf(dcf));
                        }
                        gv.Columns.Remove(dcf);
                        i--;
                    }
                    else colCount++;
                }

                iTextSharp.text.Table table = new iTextSharp.text.Table(colCount);

                table.BorderWidth = 1;
                table.BorderColor = new Color(0, 0, 255);
                table.Padding = 4;
                table.Width = 100;

                List<string> columnHeaders = new List<string>();

                for (int i = 0; i < gv.Columns.Count; i++)
                {
                    if (gv.Columns[i].Visible) columnHeaders.Add(gv.Columns[i].HeaderText);
                }

                if (args != null && args.Count > 0)
                {
                    for (int i = 0; i < colCount; i++) table.AddCell(new Cell());

                    table.AddCell(new Cell(title));
                    for (int i = 0; i < colCount - 1; i++) table.AddCell(new Cell());

                    for (int i = 0; i < colCount; i++) table.AddCell(new Cell());

                    foreach (string arg in args.Keys)
                    {
                        table.AddCell(new Cell(arg));
                        table.AddCell(new Cell(args[arg].ToString()));
                        for (int i = 0; i < colCount - 2; i++) table.AddCell(new Cell());
                    }

                    for (int i = 0; i < colCount; i++) table.AddCell(new Cell());
                }

                // create the *table* header row
                for (int i = 0; i < columnHeaders.Count; ++i)
                {
                    Cell cell = new Cell(columnHeaders[i]);
                    cell.Header = true;
                    cell.BackgroundColor = new Color(204, 204, 204);
                    table.AddCell(cell);
                }

                // data
                foreach (GridViewRow row in gv.Rows)
                {
                    var rowList = new List<Cell>();
                    GetRowDataForPdf(row, rowList, false);

                    foreach (Cell item in rowList.Take(7))
                    {
                        table.AddCell(item);
                    }
                }

                // footer
                //  add the footer row to the table
                if (gv.FooterRow != null && gv.ShowFooter)
                {
                    var footerList = new List<Cell>();
                    GetRowDataForPdf(gv.FooterRow, footerList, false);
                    foreach (Cell item in footerList)
                    {
                        table.AddCell(item);
                    }
                }

                PdfWriter.GetInstance(doc, HttpContext.Current.Response.OutputStream);

                // create document's header; 
                // set header [1] text [2] font style
                //HeaderFooter header = new HeaderFooter(
                //  new Phrase("Report Creation Date " +
                //    DateTime.UtcNow.ToString("MM-dd-yyyy "),
                //    new Font(Font.COURIER, 14)
                //  ),
                //  false
                //);
                //// top & bottom borders on by default 
                //header.Border = Rectangle.NO_BORDER;
                //// center header
                //header.Alignment = 1;
                //// add header *before* opening document
                //doc.Header = header;

                doc.Open();

                // report "title"
                Paragraph p = new Paragraph(" ");
                p.Alignment = 1;
                doc.Add(p);

                // add tabular data;    

                doc.Add(table);

                doc.Close();


            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                if (doc != null) doc.Close();
            }

            try
            {
                HttpContext.Current.Response.AddHeader("Content-Disposition", String.Format("attachment; filename={0}", fileName + ".pdf"));
                HttpContext.Current.Response.ContentType = "application/pdf";
                HttpContext.Current.Response.BufferOutput = false;
                HttpContext.Current.Response.Flush();

            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                HttpContext.Current.Response.End();
            }
        }
        #endregion

        #region public static List<string> GetRowDataForPdf(Control control)
        private static void GetRowDataForPdf(Control control, List<Cell> cellsToProcess, bool getAtMostOne)
        {
            /*******************************************
             *  Use this logic flow, in order to
             *  support multiple controls per column.
             * *****************************************
                //GridViewRow dr = (GridViewRow)control;
                //for (int i = 0; i < control.Controls.Count; i++)
                //{
                //    foreach (TableCell tc in dr.Cells)
                //    {
                //        foreach (Control current in tc.Controls)
                //        {

                //        }
                //    }
                //}
             * ****************************************/

            for (int i = 0; i < control.Controls.Count; i++)
            {
                bool recurse = true;
                var foundOne = false;
                Control current = control.Controls[i];

                if (current.GetType().ToString().Equals("System.Web.UI.WebControls.DataControlLinkButton"))
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as LinkButton).Text));
                    cellsToProcess.Add(new Cell((current as LinkButton).Text));
                    foundOne = true;
                }
                else if (current is LinkButton)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as LinkButton).Text));
                    cellsToProcess.Add(new Cell((current as LinkButton).Text));
                    foundOne = true;
                }
                else if (current is HyperLink)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as HyperLink).Text));
                    cellsToProcess.Add(new Cell((current as HyperLink).Text));
                    foundOne = true;
                }
                else if (current is DropDownList)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as DropDownList).SelectedItem.Text));
                    cellsToProcess.Add(new Cell((current as DropDownList).SelectedItem.Text));
                    foundOne = true;
                }
                else if (current is CheckBox)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as CheckBox).Checked ? "True" : "False"));
                    cellsToProcess.Add(new Cell((current as CheckBox).Checked ? "True" : "False"));
                    foundOne = true;
                }
                else if (current is Label)
                {
                    control.Controls.Remove(current);
                    if ((current as Label).Text.Contains("<b>"))
                    {
                        (current as Label).Text = (current as Label).Text.Replace("<b>", "");
                    }
                    if ((current as Label).Text.Contains("</b>"))
                    {
                        (current as Label).Text = (current as Label).Text.Replace("</b>", "");
                    }
                    if ((current as Label).Text.Contains("<br/>"))
                    {
                        (current as Label).Text = (current as Label).Text.Replace("<br/>", "\n");
                    }
                    control.Controls.AddAt(i, new LiteralControl((current as Label).Text));
                    cellsToProcess.Add(new Cell((current as Label).Text));
                    foundOne = true;
                }
                else if (current is System.Web.UI.WebControls.Image)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as System.Web.UI.WebControls.Image).ToolTip));

                    string imageUrl = (current as System.Web.UI.WebControls.Image).ImageUrl;
                    if (!String.IsNullOrEmpty(imageUrl))
                    {
                        iTextSharp.text.Image img = iTextSharp.text.Image.GetInstance(new Uri(imageUrl));
                        img.Alignment = iTextSharp.text.Image.MIDDLE_ALIGN;
                        cellsToProcess.Add(new Cell(img));
                        foundOne = true;
                    }
                    else
                    {
                        cellsToProcess.Add(new Cell(string.Empty));
                        foundOne = true;
                    }
                }
                else if (current is System.Web.UI.WebControls.Literal)
                {
                    control.Controls.Remove(current);
                    control.Controls.AddAt(i, new LiteralControl((current as Literal).Text));
                    cellsToProcess.Add(new Cell((current as Literal).Text));
                    foundOne = true;
                }
                else if (current is System.Web.UI.WebControls.TableCell)
                {
                    int idx = (control as GridViewRow).Cells.GetCellIndex((current as TableCell));
                    GridViewRow gvr = (GridViewRow)control;
                    GridView gv = (GridView)(gvr).NamingContainer;

                    if (gv.Columns[idx].Visible)
                    {
                        if (!String.IsNullOrEmpty((gvr.Cells[idx] as TableCell).Text))
                        {
                            recurse = true;
                            control.Controls.Remove(current);
                            TableCell tc = new TableCell();
                            Literal lit = new Literal();
                            lit.Text = (current as TableCell).Text;
                            tc.Controls.Add(lit);
                            control.Controls.AddAt(idx, tc);
                            //cellsToProcess.Add(new Cell((current as TableCell).Text));
                            current = tc;
                        }
                    }
                    else
                    {
                        recurse = false;
                        control.Controls.Remove(current);
                    }
                }

                if (foundOne && getAtMostOne)  // looking for one total, done
                    return;
                else if (foundOne)  // this iteration is success
                    continue;
                else if (recurse && current.HasControls())
                {
                    GetRowDataForPdf(current, cellsToProcess, true);
                }
            }
        }

        #endregion
        //#region public static void ExportToExcel(string fileName, GridView gv)
        //public static void ExportToExcel(string fileName, GridView gv)
        //{
        //    gv.GridLines = GridLines.Both;

        //    HttpContext.Current.Response.Clear();
        //    HttpContext.Current.Response.AddHeader("content-disposition", string.Format("attachment; filename={0}", fileName + ".xls"));
        //    HttpContext.Current.Response.ContentType = "application/ms-excel";

        //    using (StringWriter sw = new StringWriter())
        //    {
        //        using (HtmlTextWriter htw = new HtmlTextWriter(sw))
        //        {
        //            //  Create a table to contain the grid
        //            System.Web.UI.WebControls.Table table = new System.Web.UI.WebControls.Table();

        //            //  include the gridline settings
        //            table.GridLines = gv.GridLines;

        //            //  add the header row to the table
        //            if (gv.HeaderRow != null)
        //            {
        //                PrepareControlForExport(gv.HeaderRow);
        //                table.Rows.Add(gv.HeaderRow);
        //            }

        //            //  add each of the data rows to the table
        //            foreach (GridViewRow row in gv.Rows)
        //            {
        //                PrepareControlForExport(row);
        //                table.Rows.Add(row);
        //            }

        //            //  add the footer row to the table
        //            if (gv.FooterRow != null)
        //            {
        //                PrepareControlForExport(gv.FooterRow);
        //                table.Rows.Add(gv.FooterRow);
        //            }

        //            //  render the table into the htmlwriter
        //            table.RenderControl(htw);

        //            //  render the htmlwriter into the response
        //            HttpContext.Current.Response.Write(sw.ToString());
        //            HttpContext.Current.Response.End();
        //        }
        //    }
        //}
        //#endregion

        //#region private static void PrepareControlForExport(Control control)
        //private static void PrepareControlForExport(Control control)
        //{
        //    for (int i = 0; i < control.Controls.Count; i++)
        //    {
        //        Control current = control.Controls[i];
        //        if (current is LinkButton)
        //        {
        //            control.Controls.Remove(current);
        //            control.Controls.AddAt(i, new LiteralControl((current as LinkButton).Text));
        //        }
        //        else if (current is ImageButton)
        //        {
        //            control.Controls.Remove(current);
        //            control.Controls.AddAt(i, new LiteralControl((current as ImageButton).AlternateText));
        //        }
        //        else if (current is HyperLink)
        //        {
        //            control.Controls.Remove(current);
        //            control.Controls.AddAt(i, new LiteralControl((current as HyperLink).Text));
        //        }
        //        else if (current is DropDownList)
        //        {
        //            control.Controls.Remove(current);
        //            control.Controls.AddAt(i, new LiteralControl((current as DropDownList).SelectedItem.Text));
        //        }
        //        else if (current is CheckBox)
        //        {
        //            control.Controls.Remove(current);
        //            control.Controls.AddAt(i, new LiteralControl((current as CheckBox).Checked ? "True" : "False"));
        //        }
        //        else if (current is Label)
        //        {
        //            control.Controls.Remove(current);
        //            control.Controls.AddAt(i, new LiteralControl((current as Label).Text));
        //        }


        //        if (current.HasControls())
        //        {
        //            PrepareControlForExport(current);
        //        }
        //    }
        //}
        //#endregion

        //#region public static void ExportToPDF(string fileName, GridView gv)
        //public static void ExportToPDFlv(string fileName, ListView lv)
        //{

        //    //Create a table

        //    iTextSharp.text.Table table = new iTextSharp.text.Table(2);

        //    table.Cellpadding = 5;

        //    //Set the column widths 

        //    int[] widths = new int[2];

        //    iTextSharp.text.Cell cell = new iTextSharp.text.Cell("Facility#");

        //    cell.BackgroundColor = new Color(System.Drawing.ColorTranslator.FromHtml("#008000"));

        //    table.AddCell(cell);
        //    iTextSharp.text.Cell cell2 = new iTextSharp.text.Cell("Facility2");

        //    cell2.BackgroundColor = new Color(System.Drawing.ColorTranslator.FromHtml("#008000"));

        //    table.AddCell(cell2);

        //    table.SetWidths(widths);



        //    //Transfer rows from GridView to table

        //    for (int i = 0; i < lv.Items.Count; i++)
        //    {

        //        if (lv.Items[i].ItemType == ListViewItemType.DataItem)
        //        {

        //            for (int j = 0; j < 3; j++)
        //            {

        //                string cellText = lv.Items[i].Controls[j].ToString();

        //                iTextSharp.text.Cell cell3 = new iTextSharp.text.Cell(cellText);



        //                //Set Color of Alternating row

        //                if (i % 2 != 0)
        //                {

        //                    cell3.BackgroundColor = new Color(System.Drawing.ColorTranslator.FromHtml("#C2D69B"));

        //                }

        //                table.AddCell(cell3);

        //            }

        //        }

        //    }



        //    //Create the PDF Document

        //    Document pdfDoc = new Document(PageSize.A4, 10f, 10f, 10f, 0f);

        //    PdfWriter.GetInstance(pdfDoc, HttpContext.Current.Response.OutputStream);

        //    pdfDoc.Open();

        //    pdfDoc.Add(table);

        //    pdfDoc.Close();

        //    HttpContext.Current.Response.ContentType = "application/pdf";

        //    HttpContext.Current.Response.AddHeader("content-disposition", "attachment;" +

        //                                   "filename=GridViewExport.pdf");

        //    HttpContext.Current.Response.Cache.SetCacheability(HttpCacheability.NoCache);

        //    HttpContext.Current.Response.Write(pdfDoc);

        //    HttpContext.Current.Response.End();

        //}


        //public static void ExportToPDF(string fileName, GridView gv, string reportTitle)
        //{
        //    // initialize cells;
        //    cells.Clear();
        //    Document doc = new Document(PageSize.LEGAL.Rotate(), 0, 0, 15, 15);
        //    StringBuilder strData = new StringBuilder(string.Empty);
        //    try
        //    {
        //        StringWriter sw = new StringWriter();
        //        sw.WriteLine(Environment.NewLine);
        //        sw.WriteLine(Environment.NewLine);
        //        sw.WriteLine(Environment.NewLine);
        //        sw.WriteLine(Environment.NewLine);
        //        HtmlTextWriter htw = new HtmlTextWriter(sw);

        //        iTextSharp.text.Table table = new iTextSharp.text.Table(gv.Columns.Count);

        //        table.BorderWidth = 1;
        //        table.BorderColor = new Color(0, 0, 255);
        //        table.Padding = 4;
        //        table.Width = 100;

        //        List<string> columnHeaders = new List<string>();

        //        for (int i = 0; i < gv.Columns.Count; i++)
        //        {
        //            columnHeaders.Add(gv.Columns[i].HeaderText);
        //        }

        //        // create the *table* header row
        //        for (int i = 0; i < columnHeaders.Count; ++i)
        //        {
        //            Cell cell = new Cell(columnHeaders[i]);
        //            cell.Header = true;
        //            cell.BackgroundColor = new Color(204, 204, 204);
        //            table.AddCell(cell);
        //        }
        //        List<string> rowList = new List<string>();
        //        List<string> rowListFiltered = new List<string>();
        //        foreach (GridViewRow row in gv.Rows)
        //        {
        //            rowList.Clear();
        //            rowList = GetRowDataForPdf(row);


        //            foreach (string item in rowList)
        //            {
        //                table.AddCell(item);
        //            }
        //        }

        //        List<string> footer = new List<string>();
        //        //  add the footer row to the table
        //        if (gv.FooterRow != null && gv.ShowFooter)
        //        {
        //            footer = GetRowDataForPdf(gv.FooterRow);
        //            foreach (string item in footer)
        //            {
        //                table.AddCell(item);
        //            }
        //        }

        //        PdfWriter.GetInstance(doc, HttpContext.Current.Response.OutputStream);

        //        // create document's header; 
        //        // set header [1] text [2] font style
        //        //HeaderFooter header = new HeaderFooter(
        //        //  new Phrase("Report Creation Date " +
        //        //    DateTime.UtcNow.ToString("MM-dd-yyyy "),
        //        //    new Font(Font.COURIER, 14)
        //        //  ),
        //        //  false
        //        //);
        //        //// top & bottom borders on by default 
        //        //header.Border = Rectangle.NO_BORDER;
        //        //// center header
        //        //header.Alignment = 1;
        //        //// add header *before* opening document
        //        //doc.Header = header;

        //        doc.Open();

        //        // report "title"
        //        Paragraph p = new Paragraph(reportTitle);
        //        p.Alignment = 1;
        //        doc.Add(p);

        //        // add tabular data;    

        //        doc.Add(table);

        //        doc.Close();


        //    }
        //    catch (Exception ex)
        //    {
        //        throw ex;
        //    }
        //    finally
        //    {
        //        if (doc != null) doc.Close();
        //    }

        //    try
        //    {

        //        HttpContext.Current.Response.AddHeader("Content-Disposition", String.Format("attachment; filename={0}", fileName + ".pdf"));
        //        HttpContext.Current.Response.ContentType = "application/pdf";
        //        HttpContext.Current.Response.BufferOutput = false;
        //        HttpContext.Current.Response.Flush();
        //        HttpContext.Current.Response.End();


        //    }
        //    catch (Exception ex)
        //    {
        //        throw ex;
        //    }
        //}
        //#endregion

        //#region public static List<string> GetRowDataForPdf(Control control)
        //public static List<string> GetRowDataForPdf(Control control)
        //{

        //    for (int i = 0; i < control.Controls.Count; i++)
        //    {
        //        Control current = control.Controls[i];
        //        if (current is LinkButton)
        //        {
        //            control.Controls.Remove(current);
        //            control.Controls.AddAt(i, new LiteralControl((current as LinkButton).Text));
        //            cells.Add(((current as LinkButton).Text));
        //        }
        //        else if (current is HyperLink)
        //        {
        //            control.Controls.Remove(current);
        //            control.Controls.AddAt(i, new LiteralControl((current as HyperLink).Text));
        //            cells.Add(((current as HyperLink).Text));

        //        }
        //        else if (current is DropDownList)
        //        {
        //            control.Controls.Remove(current);
        //            control.Controls.AddAt(i, new LiteralControl((current as DropDownList).SelectedItem.Text));
        //            cells.Add(((current as DropDownList).SelectedItem.Text));
        //        }
        //        else if (current is CheckBox)
        //        {
        //            control.Controls.Remove(current);
        //            control.Controls.AddAt(i, new LiteralControl((current as CheckBox).Checked ? "True" : "False"));
        //            cells.Add(((current as CheckBox).Checked ? "True" : "False"));
        //        }
        //        else if (current is Label)
        //        {
        //            control.Controls.Remove(current);
        //            if ((current as Label).Text.Contains("<b>"))
        //            {
        //                (current as Label).Text = (current as Label).Text.Replace("<b>", "");
        //            }
        //            if ((current as Label).Text.Contains("</b>"))
        //            {
        //                (current as Label).Text = (current as Label).Text.Replace("</b>", "");
        //            }
        //            if ((current as Label).Text.Contains("<br/>"))
        //            {
        //                (current as Label).Text = (current as Label).Text.Replace("<br/>", "\n");
        //            }
        //            control.Controls.AddAt(i, new LiteralControl((current as Label).Text));
        //            cells.Add(((current as Label).Text));
        //        }


        //        if (current.HasControls())
        //        {
        //            GetRowDataForPdf(current);
        //        }
        //    }

        //    return cells;
        //}
        //#endregion

        #endregion
        #region "Show popup"
        /// <summary>
        /// Shows the pop up MSG (alert box) on current screen.
        /// </summary>
        /// <param name="msg">The MSG.</param>
        /// <param name="curpage">The curpage.</param>
        public static void ShowPopUpMsg(string msg, Page curpage)
        {
            Type t = curpage.GetType();
            string strMsg = formatPopUpString(msg);
            // Build the JavaScript String
            StringBuilder sb = new System.Text.StringBuilder();
            sb.Append("<script language='javascript'>");
            sb.Append("alert('" + strMsg + "');");
            sb.Append("</script>");
            //use the following for AJax
            if (!curpage.ClientScript.IsClientScriptBlockRegistered(t, "MsgPopUpScript"))
            { ScriptManager.RegisterClientScriptBlock(curpage, t, "MsgPopUpScript", sb.ToString(), false); }

        }

        /// <summary>
        /// Shows the pop up MSG and redirect to next page.
        /// </summary>
        /// <param name="msg">The MSG.</param>
        /// <param name="curpage">The curpage.</param>
        /// <param name="nextPagePath">The next page path.</param>
        public static void ShowPopUpMsgAndRedirect(string msg, Page curpage, string nextPagePath)
        {
            Type t = curpage.GetType();
            msg = formatPopUpString(msg);
            // Build the JavaScript String
            StringBuilder sb = new System.Text.StringBuilder();
            sb.Append("<script language='javascript'>");
            sb.Append("alert('" + msg + "');window.location.href='" + nextPagePath + "';");
            sb.Append("</script>");
            //use the following for AJax
            if (!curpage.ClientScript.IsClientScriptBlockRegistered(t, "MsgPopUpScript"))
            { System.Web.UI.ScriptManager.RegisterClientScriptBlock(curpage, t, "MsgPopUpScript", sb.ToString(), false); }

        }

        /// <summary>
        /// Formats the pop up string.
        /// </summary>
        /// <param name="msg">The MSG.</param>
        /// <returns></returns>
        public static string formatPopUpString(string msg)
        {
            StringBuilder sb = new StringBuilder(msg);
            sb.Replace("<br />", "\\n");
            //Convert the double quote
            sb.Replace("&quot;", "\"");
            return sb.ToString();

        }

        public static LoginUser CheckSession(Page currentpage)
        {
            LoginUser retUser = null;

            if (HttpContext.Current.Session[ApplicationConstants.SESSION_USEROBJLOGINDET] == null)
            {
                //cannot use server.transfer for AJAX               
                currentpage.Response.Redirect("~/Login.aspx");

            }
            else
            { retUser = (LoginUser)HttpContext.Current.Session[ApplicationConstants.SESSION_USEROBJLOGINDET]; }
            return retUser;
        }
        #endregion

        #region "Collection"
        /// <summary>
        /// Use this function to get the selected sub type collection
        /// </summary>
        /// <param name="cblst">The subtype checkboxlist of a location type.</param>
        public static CategoryCollection GetSubTypeCollection(CheckBoxList cblst)
        {
            CategoryCollection catColSubType = new CategoryCollection();
            for (int i = 0; i < cblst.Items.Count; i++)
            {
                if (cblst.Items[i].Selected)
                {
                    if (cblst.Items[i].Text.ToLower() == "all")
                    {
                        return null;
                    }
                    else
                        //add them into collection
                        catColSubType.Add(new Category(int.Parse(cblst.Items[i].Value), cblst.Items[i].Text));

                }
            }

            if (catColSubType.Count > 0)
            { return catColSubType; }
            else
            { return null; }

        }

        public static CategoryCollection GetSelItemCollection(ListBox lbitem)
        {
            CategoryCollection catColSubType = new CategoryCollection();
            for (int i = 0; i < lbitem.Items.Count; i++)
            {
                //add them into collection
                catColSubType.Add(new Category(int.Parse(lbitem.Items[i].Value), lbitem.Items[i].Text));

            }

            if (catColSubType.Count > 0)
            { return catColSubType; }
            else
            { return null; }

        }
        public static String GetStringDescFromListBox(ListBox lbitem)
        {
            String value = string.Empty;
            for (int i = 0; i < lbitem.Items.Count; i++)
            {

                //add them into string
                value += lbitem.Items[i].Text + "; ";


            }
            //chop of extra comma
            if (value.Length > 0)
            {
                value = value.Substring(0, value.Length - 2);
            }
            else
            {
                value = string.Empty;
            }
            return value;
        }

        public static String GetStringIDsFromListBox(ListBox lbitem)
        {
            String value = string.Empty;
            for (int i = 0; i < lbitem.Items.Count; i++)
            {

                //add them into string
                value += lbitem.Items[i].Value + ",";


            }
            //chop of extra comma
            if (value.Length > 0)
            {
                value = value.Substring(0, value.Length - 1);
            }
            else
            {
                value = string.Empty;
            }
            return value;
        }
        /// <summary>
        /// Check user selected sub types for a checkbox list.
        /// </summary>
        /// <param name="cblst">The checkboxlist.</param>
        public static bool CheckSubTypeCollection(CheckBoxList cblst, CategoryCollection catColSubType)
        {
            bool blOtherText = false;

            if (catColSubType != null && cblst.Items.Count > 0)
            {
                //uncheck previous values first (it may have old value when selecting other people)  
                for (int i = 0; i < cblst.Items.Count; i++)
                {
                    cblst.Items[i].Selected = false;
                }

                foreach (Category cat in catColSubType)
                {
                    if (cblst.Items.FindByValue(cat.Key.ToString()) != null)
                        cblst.Items.FindByValue(cat.Key.ToString()).Selected = true;
                    if (cat.Description.ToUpper() == ApplicationConstants.FORM_TXT_OTHER.ToUpper())
                        blOtherText = true;
                }
            }

            return blOtherText;
        }

        public static bool OtherOptionSelected(CheckBoxList cblst)
        {
            bool blOther = false;

            //uncheck previous values first (it may have old value when selecting other people)  
            for (int i = 0; i < cblst.Items.Count; i++)
            {
                if (cblst.Items[i].Selected && cblst.Items[i].Text.ToUpper() == ApplicationConstants.FORM_TXT_OTHER.ToUpper())
                    return true;
            }

            return blOther;
        }

        public static void CheckCheckboxListFromListString(ListControl cblst, string strValues)
        {

            if (!string.IsNullOrEmpty(strValues) && cblst.Items.Count > 0)
            {
                //uncheck previous values first (it may have old value when selecting other people)  
                for (int i = 0; i < cblst.Items.Count; i++)
                {
                    cblst.Items[i].Selected = false;
                }

                char[] splitter = { ',' };
                string[] strList = strValues.Split(splitter);

                for (int x = 0; x < strList.Length; x++)
                {
                    System.Web.UI.WebControls.ListItem lstItem = cblst.Items.FindByValue(strList[x]);
                    if (lstItem != null)
                    {
                        cblst.Items.FindByValue(strList[x].ToString()).Selected = true;
                    }
                }
            }
            else
            {
                foreach (System.Web.UI.WebControls.ListItem item in cblst.Items)
                {
                    item.Selected = false;
                }
            }


        }

        /// <summary>
        /// Uns the check type collection.
        /// </summary>
        /// <param name="cblst">The CBLST.</param>
        public static void UnCheckTypeCollection(CheckBoxList cblst)
        {

            if (cblst.Items.Count > 0)
            {


                for (int i = 0; i < cblst.Items.Count; i++)
                {
                    cblst.Items[i].Selected = false;

                }

            }
        }

        /// <summary>
        /// Populates the category collection with values from the DataSet.
        /// </summary>
        /// <param name="ds">The dataset.</param>
        /// <returns><see cref="CategoryCollection"/></returns>
        public static CategoryCollection PopulateCatCollection(DataSet ds)
        {
            CategoryCollection catCollection = null;
            if (ds != null)
            {
                if ((ds.Tables.Count > 0) && (ds.Tables[0].Rows.Count > 0))
                {
                    catCollection = new CategoryCollection();

                    foreach (DataRow row in ds.Tables[0].Rows)
                    {
                        catCollection.Add(new Category((int)row[0], (string)row[1]));
                    }
                }
            }
            return catCollection;
        }


        public static String GetStringKeyListFromDataSet(DataSet ds)
        {
            String value = null;

            if ((ds.Tables.Count > 0) && (ds.Tables[0].Rows.Count > 0))
            {
                value = "";
                //loop through the collection

                foreach (DataRow row in ds.Tables[0].Rows)
                {
                    value += row[0].ToString() + ",";
                }

                //chop of extra comma
                if (value.Length > 0)
                {
                    value = value.Substring(0, value.Length - 1);
                }
            }

            return value;
        }

        public static Dictionary<string, string> PopulateDictionary(DataSet ds)
        {
            Dictionary<string, string> dicCollection = null;
            if (ds != null)
            {
                if ((ds.Tables.Count > 0) && (ds.Tables[0].Rows.Count > 0))
                {
                    dicCollection = new Dictionary<string, string>();

                    foreach (DataRow row in ds.Tables[0].Rows)
                    {
                        dicCollection.Add((string)row[0], (string)row[1]);
                    }
                }
            }
            return dicCollection;
        }

        /// <summary>
        /// Populates the cat collection from string.
        /// </summary>
        /// <param name="strInput">The STR input.</param>
        /// <returns></returns>
        public static CategoryCollection PopulateCatCollectionFromString(string strInput)
        {

            CategoryCollection catCollection = null;
            if (strInput != string.Empty)
            {
                catCollection = new CategoryCollection();

                string strCurrent = "";
                int intKey = -1;
                string strDesc = "";
                char[] splitter = { ';' };

                string[] strValues = strInput.Split(splitter);

                for (int x = 0; x < strValues.Length; x++)
                {
                    strCurrent = strValues[x];
                    int pos = strCurrent.IndexOf(",");
                    intKey = Convert.ToInt32(strCurrent.Substring(0, pos));
                    strDesc = strCurrent.Substring(pos + 1, strCurrent.Length - pos - 1);
                    catCollection.Add(new Category(intKey, strDesc));
                }
            }
            return catCollection;
        }

        /// <summary>
        /// Gets a comma delimited string value of category collection
        /// </summary>
        /// <param name="catCollection">The category collection.</param>
        /// <returns><c>String</c>Comma delimited list of values</returns>
        public static String GetCatCollectionString(CategoryCollection catCollection)
        {
            String value = null;

            if ((catCollection != null) && (catCollection.Count > 0))
            {
                value = "";
                //loop through the collection
                foreach (Category category in catCollection)
                {
                    value += category.Key + ",";
                }

                //chop of extra comma
                if (value.Length > 0)
                {
                    value = value.Substring(0, value.Length - 1);
                }
                else
                {
                    value = null;
                }
            }

            return value;
        }

        public static String GetDictionaryCollectionString(Dictionary<string, string> dicCollection)
        {
            String value = null;

            if ((dicCollection != null) && (dicCollection.Count > 0))
            {
                value = "";
                //loop through the collection
                foreach (KeyValuePair<string, string> pair in dicCollection)
                {
                    value += pair.Key + ",";
                }

                //chop of extra comma
                if (value.Length > 0)
                {
                    value = value.Substring(0, value.Length - 1);
                }
                else
                {
                    value = null;
                }
            }

            return value;
        }

        /// <summary>
        /// Gets the list string from checkbox list.
        /// </summary>
        /// <param name="cblst">The CBLST.</param>
        /// <returns></returns>
        public static String GetListStringFromCheckboxList(ListControl cblst)
        {
            String value = string.Empty; ;
            if (cblst.Visible && cblst.Enabled && cblst.Items.Count > 0)
            {
                for (int i = 0; i < cblst.Items.Count; i++)
                {
                    if (cblst.Items[i].Selected)
                    {
                        if (cblst.Items[i].Text.ToLower() == "all")
                        {
                            return string.Empty;
                        }
                        else
                            //add them into collection
                            value += cblst.Items[i].Text + ",";
                        //value += int.Parse(cblst.Items[i].Value) + ",";


                    }
                }
                //chop of extra comma
                if (value.Length > 0)
                {
                    value = value.Substring(0, value.Length - 1);
                }
                else
                {
                    value = string.Empty;
                }
            }

            return value;
        }

        /// <summary>
        /// Gets the list string descs from checkbox list.
        /// </summary>
        /// <param name="cblst">The CBLST.</param>
        /// <returns></returns>
        public static String GetListStringDescFromListControl(ListControl cblst)
        {
            String value = string.Empty;
            if (cblst.Visible && cblst.Enabled && cblst.Items.Count > 0)
            {
                for (int i = 0; i < cblst.Items.Count; i++)
                {
                    if (cblst.Items[i].Selected)
                    {
                        //add them into string
                        value += cblst.Items[i].Text + ", ";

                    }
                }
                //chop of extra comma
                if (value.Length > 0)
                {
                    value = value.Substring(0, value.Length - 2);
                }
                else
                {
                    value = string.Empty;
                }
            }

            return value;
        }

        /// <summary>
        /// Gets the list string descs from checkbox list.
        /// </summary>
        /// <param name="cblst">The CBLST.</param>
        /// <returns></returns>
        public static String GetListStringDescFromListControl(ListControl cblst, string strValues)
        {
            strValues = "||" + strValues.Replace(",", "||") + "||";
            String value = string.Empty;
            if (cblst.Items.Count > 0)
            {
                for (int i = 0; i < cblst.Items.Count; i++)
                {
                    if (strValues.Contains("||" + cblst.Items[i].Value + "||"))
                    {
                        //add them into string
                        value += cblst.Items[i].Text + ", ";
                    }
                }
                //chop of extra comma
                if (value.Length > 0)
                {
                    value = value.Substring(0, value.Length - 2);
                }
                else
                {
                    value = string.Empty;
                }
            }

            return value;
        }

        /// <summary>
        /// Gets the cat collection description string. (for example, name1,name2)
        /// </summary>
        /// <param name="catCollection">The cat collection.</param>
        /// <returns></returns>
        public static String GetCatCollectionDescString(CategoryCollection catCollection)
        {
            String value = String.Empty;

            if ((catCollection != null) && (catCollection.Count > 0))
            {
                value = "";
                //loop through the collection
                foreach (Category category in catCollection)
                {
                    value += category.Description + ", ";
                }

                //chop of extra comma
                if (value.Length > 0)
                {
                    value = value.Substring(0, value.Length - 2);
                }
                else
                {
                    value = String.Empty;
                }
            }

            return value;
        }

        public static bool IsAllowedExtension(string extension)
        {
            return string.IsNullOrEmpty(extension) ? false : AllowedExtensions.Any(x => x == extension.ToUpper());
        }

        #endregion
        static Utils()
        {
            //
            // TODO: Add constructor logic here
            //
        }
    }
}