\set ECHO 0
BEGIN;
\set QUIET 1
\i sql/explain-table.sql
\set QUIET 0

-- Need to mock md5() so that it emits known values, so the tests will pass.
CREATE SCHEMA mock;

CREATE TEMPORARY SEQUENCE md5seq;
CREATE TEMPORARY TABLE md5s (
    md5 TEXT,
    id  INTEGER DEFAULT NEXTVAL('md5seq')
);

INSERT INTO md5s VALUES
('6e9d7e0628d306480fece89e8483fe6e'),
('b012abc1673778343cb1b89aae1e9b94'),
('029dde3a3c872f0c960f03d2ecfaf5ee'),
('3e4c4968cee7653037613c234a953be1'),
('dd3d1b1fb6c70be827075e01b306250c'),
('037a8fe70739ed1be6a3006d0ab80c82'),
('2c4e922dc19ce9f01a3bf08fbd76b041'),
('709b2febd8e560dd8830f4c7277c3758'),
('9dd89be09ea07a1000a21cbfc09121c7'),
('8dc3d35ab978f6c6e46f7927e7b86d21'),
('3d7c72f13ae7571da70f434b5bc9e0af');

CREATE FUNCTION mock.md5(TEXT) RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
    rec md5s;
BEGIN
    SELECT * INTO rec FROM md5s WHERE id = (SELECT MIN(id) FROM md5s);
     DELETE FROM md5s WHERE id = rec.id;
     RETURN rec.md5;
END;
$$;

SET search_path = mock,public,pg_catalog;

-- Okay, now on with the tests. Create a table to query against.
CREATE TABLE foo(id int);

-- Plan an explain and an explain analyze.
SELECT * FROM plan('select * from foo');

-- Plan an explain analyze. Omit imes because it varies. :-(
SELECT "Node ID", "Parent ID", "Node Type", "Total Runtime" IS NOT NULL as "Have Total Runtime", "Strategy", "Operation", "Startup Cost", "Total Cost", "Plan Rows", "Plan Width", "Actual Startup Time" IS NOT NULL AS "Have Actual Startup Time", "Actual Total Time" IS NOT NULL AS "Have Actual Total Time", "Actual Rows", "Actual Loops", "Parent Relationship", "Sort Key", "Sort Method", "Sort Space Used", "Sort Space Type", "Join Type", "Join Filter", "Hash Cond", "Relation Name", "Alias", "Scan Direction", "Index Name", "Index Cond", "Recheck Cond", "TID Cond", "Merge Cond", "Subplan Name", "Function Name", "Function Call", "Filter", "One-Time Filter", "Command", "Shared Hit Blocks", "Shared Read Blocks", "Shared Written Blocks", "Local Hit Blocks", "Local Read Blocks", "Local Written Blocks", "Temp Read Blocks", "Temp Written Blocks", "Output", "Hash Buckets", "Hash Batches", "Original Hash Batches", "Peak Memory Usage", "Schema", "CTE Name" FROM plan('select * from foo', true);

-- Make sure parse_node() recurses.
SELECT * FROM parse_node($$     <Plan>
       <Node-Type>Aggregate</Node-Type>
       <Strategy>Sorted</Strategy>
       <Startup-Cost>258.13</Startup-Cost>
       <Total-Cost>262.31</Total-Cost>
       <Plan-Rows>4</Plan-Rows>
       <Plan-Width>324</Plan-Width>
       <Actual-Startup-Time>0.121</Actual-Startup-Time>
       <Actual-Total-Time>0.121</Actual-Total-Time>
       <Actual-Rows>0</Actual-Rows>
       <Actual-Loops>1</Actual-Loops>
       <Plans>
         <Plan>
           <Node-Type>Sort</Node-Type>
           <Parent-Relationship>Outer</Parent-Relationship>
           <Startup-Cost>258.13</Startup-Cost>
           <Total-Cost>258.14</Total-Cost>
           <Plan-Rows>4</Plan-Rows>
           <Plan-Width>324</Plan-Width>
           <Actual-Startup-Time>0.117</Actual-Startup-Time>
           <Actual-Total-Time>0.117</Actual-Total-Time>
           <Actual-Rows>0</Actual-Rows>
           <Actual-Loops>1</Actual-Loops>
           <Sort-Key>
             <Item>d.name</Item>
             <Item>d.version</Item>
             <Item>d.abstract</Item>
             <Item>d.description</Item>
             <Item>d.relstatus</Item>
             <Item>d.owner</Item>
             <Item>d.sha1</Item>
             <Item>d.meta</Item>
           </Sort-Key>
           <Sort-Method>quicksort</Sort-Method>
           <Sort-Space-Used>25</Sort-Space-Used>
           <Sort-Space-Type>Memory</Sort-Space-Type>
           <Plans>
             <Plan>
               <Node-Type>Nested Loop</Node-Type>
               <Parent-Relationship>Outer</Parent-Relationship>
               <Join-Type>Left</Join-Type>
               <Startup-Cost>16.75</Startup-Cost>
               <Total-Cost>258.09</Total-Cost>
               <Plan-Rows>4</Plan-Rows>
               <Plan-Width>324</Plan-Width>
               <Actual-Startup-Time>0.009</Actual-Startup-Time>
               <Actual-Total-Time>0.009</Actual-Total-Time>
               <Actual-Rows>0</Actual-Rows>
               <Actual-Loops>1</Actual-Loops>
               <Join-Filter>(semver_cmp(d.version, dt.version) = 0)</Join-Filter>
               <Plans>
                 <Plan>
                   <Node-Type>Hash Join</Node-Type>
                   <Parent-Relationship>Outer</Parent-Relationship>
                   <Join-Type>Inner</Join-Type>
                   <Startup-Cost>16.75</Startup-Cost>
                   <Total-Cost>253.06</Total-Cost>
                   <Plan-Rows>4</Plan-Rows>
                   <Plan-Width>292</Plan-Width>
                   <Actual-Startup-Time>0.009</Actual-Startup-Time>
                   <Actual-Total-Time>0.009</Actual-Total-Time>
                   <Actual-Rows>0</Actual-Rows>
                   <Actual-Loops>1</Actual-Loops>
                   <Hash-Cond>(de.distribution = d.name)</Hash-Cond>
                   <Join-Filter>(semver_cmp(d.version, de.dist_version) = 0)</Join-Filter>↵
                   <Plans>
                     <Plan>
                       <Node-Type>Seq Scan</Node-Type>
                       <Parent-Relationship>Outer</Parent-Relationship>
                       <Relation-Name>distribution_extensions</Relation-Name>
                       <Alias>de</Alias>
                       <Startup-Cost>0.00</Startup-Cost>
                       <Total-Cost>15.10</Total-Cost>
                       <Plan-Rows>510</Plan-Rows>
                       <Plan-Width>128</Plan-Width>
                       <Actual-Startup-Time>0.008</Actual-Startup-Time>
                       <Actual-Total-Time>0.008</Actual-Total-Time>
                       <Actual-Rows>0</Actual-Rows>
                       <Actual-Loops>1</Actual-Loops>
                     </Plan>
                     <Plan>
                       <Node-Type>Hash</Node-Type>
                       <Parent-Relationship>Inner</Parent-Relationship>
                       <Startup-Cost>13.00</Startup-Cost>
                       <Total-Cost>13.00</Total-Cost>
                       <Plan-Rows>300</Plan-Rows>
                       <Plan-Width>228</Plan-Width>
                       <Actual-Startup-Time>0.000</Actual-Startup-Time>
                       <Actual-Total-Time>0.000</Actual-Total-Time>
                       <Actual-Rows>0</Actual-Rows>
                       <Actual-Loops>0</Actual-Loops>
                       <Plans>
                         <Plan>
                           <Node-Type>Seq Scan</Node-Type>
                           <Parent-Relationship>Outer</Parent-Relationship>
                           <Relation-Name>distributions</Relation-Name>
                           <Alias>d</Alias>
                           <Startup-Cost>0.00</Startup-Cost>
                           <Total-Cost>13.00</Total-Cost>
                           <Plan-Rows>300</Plan-Rows>
                           <Plan-Width>228</Plan-Width>
                           <Actual-Startup-Time>0.000</Actual-Startup-Time>
                           <Actual-Total-Time>0.000</Actual-Total-Time>
                           <Actual-Rows>0</Actual-Rows>
                           <Actual-Loops>0</Actual-Loops>
                         </Plan>
                       </Plans>
                     </Plan>
                   </Plans>
                 </Plan>
                 <Plan>
                   <Node-Type>Index Scan</Node-Type>
                   <Parent-Relationship>Inner</Parent-Relationship>
                   <Scan-Direction>NoMovement</Scan-Direction>
                   <Index-Name>distribution_tags_pkey</Index-Name>
                   <Relation-Name>distribution_tags</Relation-Name>
                   <Alias>dt</Alias>
                   <Startup-Cost>0.00</Startup-Cost>
                   <Total-Cost>0.46</Total-Cost>
                   <Plan-Rows>3</Plan-Rows>
                   <Plan-Width>96</Plan-Width>
                   <Actual-Startup-Time>0.000</Actual-Startup-Time>
                   <Actual-Total-Time>0.000</Actual-Total-Time>
                   <Actual-Rows>0</Actual-Rows>
                   <Actual-Loops>0</Actual-Loops>
                   <Index-Cond>(d.name = dt.distribution)</Index-Cond>
                 </Plan>
               </Plans>
             </Plan>
           </Plans>
         </Plan>
         <Plan>
           <Node-Type>Function Scan</Node-Type>
           <Parent-Relationship>SubPlan</Parent-Relationship>
           <Subplan-Name>SubPlan 1</Subplan-Name>
           <Function-Name>unnest</Function-Name>
           <Alias>g</Alias>
           <Startup-Cost>0.00</Startup-Cost>
           <Total-Cost>1.00</Total-Cost>
           <Plan-Rows>100</Plan-Rows>
           <Plan-Width>32</Plan-Width>
           <Actual-Startup-Time>0.000</Actual-Startup-Time>
           <Actual-Total-Time>0.000</Actual-Total-Time>
           <Actual-Rows>0</Actual-Rows>
           <Actual-Loops>0</Actual-Loops>
           <Filter>(x IS NOT NULL)</Filter>
         </Plan>
       </Plans>
     </Plan>
$$);
ROLLBACK;
