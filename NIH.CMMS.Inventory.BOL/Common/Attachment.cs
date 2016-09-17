﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace NIH.CMMS.Inventory.BOL.Common
{
    [Serializable]
    public class Attachment 
    {
        public int Key;

        public string CreatedBy = "";
        public DateTime CreatedOn = DateTime.MinValue;

        public string UpdatedBy = "";
        public DateTime UpdatedOn = DateTime.MinValue;

        public string InvFacID = "";
        public int InvFacSysID;
        public string InvEquipID = string.Empty;
        public int InvEquipSysID;

        public string FileName = "";
        public string FileType = "";
        public string Title = "";
        public Byte[] FileData;

        public Attachment()
        {
        }
        
    }
}